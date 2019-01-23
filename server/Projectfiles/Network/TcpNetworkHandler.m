#include <netinet/tcp.h>
#include <netinet/in.h>

#import <Crashlytics/Answers.h>

#import "TcpNetworkHandler.h"
#import "Globals.h"
#import "LoginPacket.h"
#import "AnnouncePacket.h"
#import "JoinPacket.h"
#import "LeavePacket.h"
#import "GameEndedPacket.h"
#import "ReadyToStartPacket.h"
#import "KeepAlivePacket.h"
#import "SetupUnitsPacket.h"
#import "WindPacket.h"

#import "UdpNetworkHandler.h"
#import "LineOfSight.h"
#import "MapLayer.h"
#import "NetworkUtils.h"

#import "FireMission.h"
#import "AreaFireMission.h"
#import "SmokeMission.h"
#import "AdvanceMission.h"
#import "AssaultMission.h"
#import "ChangeModeMission.h"
#import "MeleeMission.h"
#import "MoveMission.h"
#import "MoveFastMission.h"
#import "RetreatMission.h"
#import "ScoutMission.h"
#import "IdleMission.h"
#import "DisorganizedMission.h"
#import "RallyMission.h"
#import "Engine.h"

@interface TcpNetworkHandler ()

@property (nonatomic, strong) GCDAsyncSocket *tcpSocket;
@property (nonatomic, readwrite, strong) NSMutableArray *games;
@property (nonatomic, strong) HostedGame *currentGame;
@property (nonatomic, assign) unsigned int announcedGameId;
@property (nonatomic, assign, readwrite) BOOL isConnected;
@property (nonatomic, assign, readwrite) int  playerCount;

@end

#define TAG_HEADER  0
#define TAG_PAYLOAD 1

@implementation TcpNetworkHandler

- (instancetype) init {
    self = [super init];
    if (self) {
        // create the socket
        self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.isConnected = NO;

        // no games yet
        self.games = [NSMutableArray new];
        self.currentGame = nil;

        self.delegates = [NSMutableSet set];

        // no game announced yet
        self.announcedGameId = UINT_MAX;

        // TODO: not needed?
        [self.tcpSocket performBlock:^{
            int fd = [self.tcpSocket socketFD];
            int on = 1;
            if (setsockopt( fd, IPPROTO_TCP, TCP_NODELAY, (char *) &on, sizeof( on ) ) == -1) {
                CCLOG( @"error disabling delay for TCP socket" );
            }
        }];
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
}


- (void) registerDelegate:(id <OnlineGamesDelegate>)delegate {
    if (![self.delegates containsObject:delegate]) {
        [self.delegates addObject:delegate];
        CCLOG( @"registering delegate %@, now: %lu", delegate, (unsigned long)self.delegates.count );
        for (id <OnlineGamesDelegate> tmp in self.delegates) {
            CCLOG( @"delegate %@", tmp );
        }
    }
}


- (void) deregisterDelegate:(id <OnlineGamesDelegate>)delegate {
    if ([self.delegates containsObject:delegate]) {
        [self.delegates removeObject:delegate];
        CCLOG( @"deregistering delegate %@, now: %lu", delegate, (unsigned long)self.delegates.count );
    }
}


- (BOOL) connect {
    // reset some state
    [self.games removeAllObjects];
    self.announcedGameId = UINT_MAX;
    self.currentGame = nil;

    CCLOG( @"connecting to %@:%d", sServerHost, sServerPort);

    NSError *err = nil;
    if (![self.tcpSocket connectToHost:sServerHost onPort:sServerPort withTimeout:5 error:&err]) {
        // If there was an error, it's likely something like "already connected" or "no delegate set"
        CCLOG( @"failed to connect: %@", err );
        return NO;
    }

    return YES;
}


- (void) disconnect {
    CCLOG( @"disconnecting" );
    if (self.tcpSocket) {
        [self.tcpSocket disconnect];
        self.tcpSocket = nil;
    }

    if ([Globals sharedInstance].udpConnection) {
        [[Globals sharedInstance].udpConnection disconnect];
        [Globals sharedInstance].udpConnection = nil;
    }

    self.isConnected = NO;

    [self.games removeAllObjects];

    // no more keepalive
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];
}


- (void) sendKeepAlive {
    //CCLOG( @"sending keepalive" );
    [self writePacket:[KeepAlivePacket new]];
}


- (void) loginWithName:(NSString *)name {
    self.onlineName = name;

    // we're not yet connected, but we can queue up packets anyway
    [self writePacket:[[LoginPacket alloc] initWithName:self.onlineName]];
}


- (void) announceScenario:(Scenario *)scenario {
    CCLOG( @"announcing scenario: %@", scenario );
    [self writePacket:[[AnnouncePacket alloc] initWithScenario:scenario]];
}


- (void) joinGame:(HostedGame *)game {
    CCLOG( @"joining game: %@", game );
    self.currentGame = game;
    [self writePacket:[[JoinPacket alloc] initWithGame:game]];
}


- (void) leaveGame {
    CCLOG( @"leaving game" );
    self.announcedGameId = UINT_MAX;
    [self writePacket:[LeavePacket new]];
}


- (void) sendUnits {
    CCLOG( @"sending units packet" );
    [self writePacket:[SetupUnitsPacket new]];
}


- (void) sendWind {
    CCLOG( @"sending wind packet" );
    [self writePacket:[WindPacket new]];
}


- (void) readyToStart {
    CCLOG( @"sending ready to start game indication" );
    [self writePacket:[ReadyToStartPacket new]];
}


- (void) endGame {
    [self writePacket:[GameEndedPacket new]];
}


- (void) writePacket:(TcpPacket *)packet {
    CCLOG( @"writing packet: %@", packet );

    // do the real write
    [self.tcpSocket writeData:packet.data withTimeout:-1 tag:0];
}


//***************************************************************************************************************
#pragma mark - TCP socket delegate

- (void) socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
    CCLOG( @"connected ok to %@:%d", host, port );
    self.isConnected = YES;

    // check and possibly start TLS
    if (sUnsecureOnline) {
        CCLOG( @"skipping TLS and going insecure!" );
        [self socketDidSecure:sender];
    }
    else {
        [sender startTLS:nil];
    }

    // start sending TCP keepalive
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector( sendKeepAlive ) forTarget:self interval:2.0 paused:NO];
}


- (void) socketDidSecure:(GCDAsyncSocket *)sender {
    CCLOG( @"TLS now enabled" );

    // just inform the delegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        CCLOG( @"delegate %@", delegate );
        if (delegate && [delegate respondsToSelector:@selector( connectedOk )]) {
            [delegate connectedOk];
        }
    }

    // start reading the first response
    [self.tcpSocket readDataToLength:sTcpPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
}


- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    CCLOG( @"disconnected from server" );

    self.isConnected = NO;

    // no more keepalives
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

    if (error) {
        CCLOG( @"error: %@", error );
        NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
        for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
            if (delegate && [delegate respondsToSelector:@selector( connectionFailed )]) {
                CCLOG( @"failed to connect: %@", error );
                [delegate connectionFailed];
            }
        }

        // try again after a few seconds
        dispatch_time_t delayTime = dispatch_time( DISPATCH_TIME_NOW, sReconnectDelay * NSEC_PER_SEC );
        dispatch_after( delayTime, dispatch_get_main_queue(), ^(void) {
            [self connect];
        } );
    }
}


- (void) socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    if (tag == TAG_HEADER) {
        [self handleHeader:[data bytes]];
    }
    else if (tag == TAG_PAYLOAD) {
        [self handlePayload:[data bytes] length:data.length];
    }
}


- (void) handleHeader:(const UInt8 *)data {
    unsigned short offset = 0;

    // copy data
    unsigned short payloadLength = readInt16FromBuffer( data, &offset );

    CCLOG( @"payload length: %d", payloadLength );

    // any payload?
    if (payloadLength == 0) {
        // nothing to read, just handle directly
        [self handlePayload:NULL length:0];
    }
    else {
        // start reading the payload
        [self.tcpSocket readDataToLength:payloadLength withTimeout:-1 tag:TAG_PAYLOAD];
    }
}


- (void) handlePayload:(const UInt8 *)data length:(unsigned long)length {
    unsigned short offset = 0;
    TcpNetworkPacketType packetType = (TcpNetworkPacketType) readInt16FromBuffer( data, &offset );
    CCLOG( @"packet type: %@", [TcpPacket name:packetType] );

    switch ( packetType) {
        case kLoginOkPacket:
            [self handleLoginOk];
            break;

        case kInvalidProtocolPacket:
            [self handleLoginFailed:kInvalidProtocolError];
            break;
        case kAlreadyLoggedInPacket:
            [self handleLoginFailed:kAlreadyLoggedInError];
            break;
        case kInvalidNamePacket:
            [self handleLoginFailed:kInvalidNameError];
            break;
        case kNameTakenPacket:
            [self handleLoginFailed:kNameTakenError];
            break;
        case kServerFullPacket:
            [self handleLoginFailed:kServerFullError];
            break;
        case kInvalidPasswordPacket:
            [self handleLoginFailed:kInvalidPasswordError];
            break;

        case kAlreadyAnnouncedPacket:
            [self handleAlreadyAnnounced];
            break;

        case kAnnounceOkPacket:
            [self handleAnnouncedOk:data + offset];
            break;

        case kGameAddedPacket:
            [self handleGameAdded:data + offset];
            break;

        case kGameJoinedPacket:
            [self handleGameJoined:data + offset];
            break;

        case kGameRemovedPacket:
            [self handleGameRemoved:data + offset];
            break;

        case kInvalidGamePacket:
            [self handleInvalidGame];
            break;

        case kDataPacket:
            [self handleDataPacket:data + offset];
            break;

        case kGameEndedPacket:
            [self handleGameEndedPacket];
            break;

        case kPlayerCountPacket:
            [self handlePlayerCountPacket:data + offset];
            break;

        default:
            CCLOG( @"unhandled packet type: %@", [TcpPacket name:packetType] );
            break;
    }

    // start reading the next header
    [self.tcpSocket readDataToLength:sTcpPacketHeaderLength withTimeout:-1 tag:TAG_HEADER];
}


- (void) handleLoginOk {
    CCLOG( @"logged in ok" );

    // just inform the delegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        CCLOG( @"delegate %@", delegate );
        if (delegate && [delegate respondsToSelector:@selector( loginOk )]) {
            [delegate loginOk];
        }
    }

    // log login
    [Answers logLoginWithMethod:sServerHost
                        success:@YES
               customAttributes:@{ @"onlineName" : self.onlineName } ];
}


- (void) handleLoginFailed:(NetworkLoginErrorReason)reason {
    // just inform the deletegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( loginFailed: )]) {
            [delegate loginFailed:reason];
        }
    }

    // log login failure
    [Answers logLoginWithMethod:sServerHost
                        success:@NO
               customAttributes:@{ @"onlineName" : self.onlineName } ];
}


- (void) handleAlreadyAnnounced {
    // just inform the deletegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( gameAnnounceFailed )]) {
            [delegate gameAnnounceFailed];
        }
    }
}


- (void) handleAnnouncedOk:(const UInt8 *)data {
    unsigned short offset = 0;

    // get the game id
    self.announcedGameId = readInt32FromBuffer( data, &offset );

    CCLOG( @"game announced ok, game id: %d", self.announcedGameId );

    // just inform the deletegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( gameAnnounceOk )]) {
            [delegate gameAnnounceOk];
        }
    }
}


- (void) handleGameAdded:(const UInt8 *)data {
    // if we have announced a game ok then we don't care about any other games
//    if (self.announcedGameId != UINT_MAX) {
//        CCLOG( @"we've announced a game, ignoring other announced game" );
//        return;
//    }

    unsigned short offset = 0;
    char nameBuffer[256];

    // get game data
    unsigned int gameId = readInt32FromBuffer( data, &offset );
    unsigned short scenarioId = readInt16FromBuffer( data, &offset );
    unsigned short nameLength = readInt16FromBuffer( data, &offset );

    // check all the games to see if we already have this game. We can get duplicates in some
    // fairly rare cases
    for (HostedGame *game in self.games) {
        if (game.gameId == gameId) {
            // we already have this game
            CCLOG( @"we've already received game with id %d, ignoring this version", gameId );
            return;
        }
    }

    // announcer name
    memcpy( nameBuffer, data + offset, nameLength );
    nameBuffer[nameLength] = 0;
    offset += nameLength;
    NSString *playerName = [NSString stringWithUTF8String:nameBuffer];

    // is this new game the one we announced?
    HostedGame * game;
    if (self.announcedGameId == gameId) {
        // our game, so no opponent yet
        game = [[HostedGame alloc] initWithId:gameId scenarioId:scenarioId opponentName:nil];
        self.currentGame = game;
    }
    else {
        // a game someone else announced, so they are the opponent
        game = [[HostedGame alloc] initWithId:gameId scenarioId:scenarioId opponentName:playerName];
    }

    [self.games addObject:game];
    CCLOG( @"received game: %@, games now: %lu", game, (unsigned long)self.games.count );

    // just inform the deletegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( gamesUpdated )]) {
            [delegate gamesUpdated];
        }
    }
}


- (void) handleGameJoined:(const UInt8 *)data {
    unsigned short offset = 0;
    char nameBuffer[256];

    // udp port and name length
    unsigned short udpPort = readInt16FromBuffer( data, &offset );
    unsigned short nameLength = readInt16FromBuffer( data, &offset );

    // name
    memcpy( nameBuffer, data + offset, nameLength );
    nameBuffer[nameLength] = 0;
    offset += nameLength;

    // make a string from it
    NSString *opponentName = [NSString stringWithUTF8String:nameBuffer];

    CCLOG( @"game joined ok, opponent: %@, UDP port: %d", opponentName, udpPort );

    // did we announce the game?
    if (self.currentGame.gameId != self.announcedGameId ) {
        CCLOG( @"we joined an announced game %@", self.currentGame );

        // we're always player 2 in a game we join
        self.currentGame.localPlayerId = kPlayer2;
    }
    else {
        // someone joined a game we announced, we're always player 1 in a game we host
        self.currentGame.localPlayerId = kPlayer1;
        self.currentGame.opponentName = opponentName;
        CCLOG( @"player joined our game %@", self.currentGame );
    }

    // save the UDP port
    self.currentGame.udpPort = udpPort;

    // create the UDP handler and send a few initial ping packets so that the server gets our
    [Globals sharedInstance].udpConnection = [[UdpNetworkHandler alloc] initWithServer:sServerHost port:udpPort delegate:self];

    // send a few pings with some delay
    dispatch_queue_t pingQueue = dispatch_queue_create( "com.d-pointer.imperium.ping", 0 );
    dispatch_async( pingQueue, ^(void) {
        for (int index = 0; index < 5; ++index) {
            [[Globals sharedInstance].udpConnection sendPingToServer];
            sleep( 1 );
        }
    } );

    // let the delegate know
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( gameJoined: )]) {
            [delegate gameJoined:self.currentGame];
        }
    }
}


- (void) handleGameRemoved:(const UInt8 *)data {
    unsigned short offset = 0;

    // get the game id
    unsigned int gameId = readInt32FromBuffer( data, &offset );

    HostedGame *removed = nil;

    // do we have a current game and is it ours?
    if (self.currentGame && self.currentGame.gameId == gameId) {
        // our game was removed, this just means it's no longer publicly announced
        CCLOG( @"our game is no longer publicly announced" );
        removed = self.currentGame;
        self.currentGame = nil;
    }
    else {
        // another game was removed
        for (HostedGame *game in self.games) {
            if (game.gameId == gameId) {
                removed = game;
                break;
            }
        }
    }

    if (!removed) {
        CCLOG( @"did not find removed game with id: %d", gameId );
        return;
    }

    [self.games removeObject:removed];
    CCLOG( @"game removed: %@", removed );

    // just inform the delegate, there is no extra data
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( gamesUpdated )]) {
            [delegate gamesUpdated];
        }
    }
}


- (void) handleInvalidGame {
    // the game the user chose has likely just disappeared or been started by other players
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( failedToJoinGame )]) {
            [delegate failedToJoinGame];
        }
    }
}


- (void) handleDataPacket:(const UInt8 *)data {
    unsigned int offset = 0;

    // get the sub type
    TcpNetworkPacketSubType subType = (TcpNetworkPacketSubType) data[offset++];

    switch (subType) {
        case kSetupUnitsPacket:
            [self handleSetupUnits:data + offset];
            break;

        case kGameResultPacket:
            [self handleGameResult:data + offset];
            break;

        case kWindPacket:
            [self handleWind:data + offset];
            break;
    }
}


- (void) handleGameEndedPacket {
    // this is sent by the server when the game ends, either from having ended normally or due to the other
    // player disconnecting
    CCLOG( @"game ended received from server" );

    // stop the engine
    [[Globals sharedInstance].engine stop];

    if ([Globals sharedInstance].udpConnection) {
        CCLOG( @"shutting down UDP connection" );
        [[Globals sharedInstance].udpConnection disconnect];
        [Globals sharedInstance].udpConnection = nil;
    }

    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        CCLOG( @"delegate: %@", delegate );
        if (delegate && [delegate respondsToSelector:@selector( gameEnded )]) {
            [delegate gameEnded];
        }
    }
}


- (void) handleSetupUnits:(const UInt8 *)data {
    CCLOG( @"handling setting up enemy units" );

    Globals *globals = [Globals sharedInstance];

    unsigned short offset = 0;
    unsigned char unitCount = data[offset++];

    CCLOG( @"units: %d", (int) unitCount );
    char nameBuffer[256];

    // id of the enemy
    PlayerId owner = globals.localPlayer.playerId == kPlayer1 ? kPlayer2 : kPlayer1;

    // read all the units
    for (unsigned int index = 0; index < unitCount; ++index) {
        unsigned short unitId = readInt16FromBuffer( data, &offset );
        float x = (float) readInt16FromBuffer( data, &offset ) / 10.0f;
        float y = (float) readInt16FromBuffer( data, &offset ) / 10.0f;
        float facing = (float) readInt16FromBuffer( data, &offset ) / 10.0f;
        UnitType unitType = (UnitType) data[offset++];
        unsigned char men = data[offset++];
        UnitMode mode = (UnitMode) data[offset++];
        MissionType missionType = (MissionType) data[offset++];
        unsigned char morale = data[offset++];
        unsigned char fatigue = data[offset++];
        ExperienceType experience = (ExperienceType) data[offset++];
        unsigned char ammo = data[offset++];
        WeaponType weaponType = (WeaponType) data[offset++];
        unsigned char nameLength = data[offset++];

        // copy the name
        memcpy( nameBuffer, data + offset, MIN( nameLength, 255 ) );
        nameBuffer[nameLength] = 0;
        offset += nameLength;

        // make a string from it
        NSString *unitName = [NSString stringWithUTF8String:nameBuffer];

        // create the unit
        Unit *unit = [Unit createUnitType:unitType forOwner:owner mode:kFormation men:men morale:morale fatigue:fatigue weapon:weaponType experience:experience ammo:ammo];
        unit.unitId = unitId;
        unit.name = unitName;
        unit.position = ccp( x, y );
        unit.rotation = facing;
        unit.mode = mode;

        // set up the icon
        [unit updateIcon];

        switch (missionType) {
            case kAdvanceMission:
                unit.mission = [[AdvanceMission alloc] init];
                break;
            case kAssaultMission:
                unit.mission = [[AssaultMission alloc] init];
                break;
            case kFireMission:
                unit.mission = [[FireMission alloc] init];
                break;
            case kAreaFireMission:
                unit.mission = [[AreaFireMission alloc] init];
                break;
            case kSmokeMission:
                unit.mission = [[SmokeMission alloc] init];
                break;
            case kMeleeMission:
                unit.mission = [[MeleeMission alloc] init];
                break;
            case kMoveMission:
                unit.mission = [[MoveMission alloc] init];
                break;
            case kMoveFastMission:
                unit.mission = [[MoveFastMission alloc] init];
                break;
            case kRetreatMission:
                unit.mission = [[RetreatMission alloc] init];
                break;
            case kRotateMission:
                unit.mission = [[RotateMission alloc] init];
                break;
            case kScoutMission:
                unit.mission = [[ScoutMission alloc] init];
                break;
            case kChangeModeMission:
                unit.mission = [[ChangeModeMission alloc] init];
                break;
            case kIdleMission:
                unit.mission = [[IdleMission alloc] init];
                break;
            case kDisorganizedMission:
                unit.mission = [[DisorganizedMission alloc] init];
                break;
            case kRoutMission:
                unit.mission = [[RoutMission alloc] init];
                break;
            case kRallyMission:
                unit.mission = [[RallyMission alloc] init];
                break;
        }

        // the mission needs to know the unit
        unit.mission.unit = unit;

        // add to map
        [globals.mapLayer addChild:unit z:kUnitZ];

        if (unit.unitTypeIcon) {
            [globals.mapLayer addChild:unit.unitTypeIcon z:kUnitTypeIconZ];
        }

        // and save for later
        [[Globals sharedInstance].units addObject:unit];

        // add to the right container too
        if (owner == kPlayer1) {
            [globals.unitsPlayer1 addObject:unit];
        }
        else {
            [globals.unitsPlayer2 addObject:unit];
        }

        CCLOG( @"created unit %@", unit );
    }

    CCLOG( @"total units %lu %lu %lu", (unsigned long)globals.unitsPlayer1.count, (unsigned long)globals.unitsPlayer2.count, (unsigned long)globals.units.count );

    // initial line of sight update now that we have all units
    globals.lineOfSight = [LineOfSight new];
    [globals.lineOfSight update];

    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        CCLOG( @"delegate: %@", delegate );
        if (delegate && [delegate respondsToSelector:@selector( unitsReceived )]) {
            [delegate unitsReceived];
        }
    }

    // we're now ready
    [self readyToStart];
}


- (void) handleGameResult:(const UInt8 *)data {
    unsigned short offset = 0;

    CCLOG( @"game has been completed" );

    // stop the engine
    [[Globals sharedInstance].engine stop];

    if ([Globals sharedInstance].udpConnection) {
        CCLOG( @"shutting down UDP connection" );
        [[Globals sharedInstance].udpConnection disconnect];
        [Globals sharedInstance].udpConnection = nil;
    }

    // extract all data
    unsigned char endingType = data[offset++];
    unsigned short totalMen1 = readInt16FromBuffer( data, &offset );
    unsigned short totalMen2 = readInt16FromBuffer( data, &offset );
    unsigned short lostMen1 = readInt16FromBuffer( data, &offset );
    unsigned short lostMen2 = readInt16FromBuffer( data, &offset );
    unsigned short objectives1 = readInt16FromBuffer( data, &offset );
    unsigned short objectives2 = readInt16FromBuffer( data, &offset );

    CCLOG( @"end type: %d, total: %d, %d, lost: %d, %d, objectives: %d, %d", endingType, totalMen1, totalMen2, lostMen1, lostMen2, objectives1, objectives2 );

    // save the ending type in the online game
    [Globals sharedInstance].onlineGame.endType = (MultiplayerEndType) endingType;

    // set the scores before showing any UI
    [[Globals sharedInstance].scores setTotalMen1:totalMen1
                                        totalMen2:totalMen2
                                         lostMen1:lostMen1
                                         lostMen2:lostMen2
                                      objectives1:objectives1
                                      objectives2:objectives2];

    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        CCLOG( @"delegate: %@", delegate );
        if (delegate && [delegate respondsToSelector:@selector( gameCompleted )]) {
            [delegate gameCompleted];
        }
    }
}


- (void) handleWind:(const UInt8 *)data {
    unsigned short offset = 0;

    Scenario * scenario = [Globals sharedInstance].scenario;
    scenario.windDirection = (float) readInt16FromBuffer( data, &offset ) / 10.0f;
    scenario.windStrength  = (float) readInt16FromBuffer( data, &offset ) / 10.0f;

    CCLOG( @"received wind direction: %.1f, strength: %.1f", scenario.windDirection, scenario.windStrength );
}


//***************************************************************************************************************
#pragma mark - Player count

- (void) handlePlayerCountPacket:(const UInt8 *)data {
    unsigned short offset = 0;

    self.playerCount = readInt16FromBuffer( data, &offset );
    CCLOG( @"current server player count: %d", self.playerCount );

    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( playerCountUpdated: )]) {
            [delegate playerCountUpdated:self.playerCount];
        }
    }
}


//***************************************************************************************************************
#pragma mark - UDP network handler delegate

- (void) serverPongReceived:(double)milliseconds {
    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( serverPongReceived: )]) {
            [delegate serverPongReceived:milliseconds];
        }
    }
}

- (void) playerPongReceived:(double)milliseconds {
    // inform the delegates
    NSSet *copiedDelegates = [NSSet setWithSet:self.delegates];
    for (id <OnlineGamesDelegate> delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:@selector( playerPongReceived: )]) {
            [delegate playerPongReceived:milliseconds];
        }
    }
}

@end
