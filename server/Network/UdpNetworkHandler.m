#import "UdpNetworkHandler.h"
#import "Globals.h"
#import "GameLayer.h"
#import "Engine.h"
#import "ServerPingPacket.h"
#import "MissionPacket.h"
#import "UnitStatsPacket.h"
#import "SmokePacket.h"
#import "NetworkUtils.h"
#import "Smoke.h"

#import "AdvanceMission.h"
#import "AssaultMission.h"
#import "ChangeModeMission.h"
#import "DisorganizedMission.h"
#import "FireMission.h"
#import "AreaFireMission.h"
#import "SmokeMission.h"
#import "IdleMission.h"
#import "MeleeMission.h"
#import "MoveFastMission.h"
#import "Unit.h"
#import "MoveMission.h"
#import "RallyMission.h"
#import "RetreatMission.h"
#import "ScoutMission.h"
#import "CombatMission.h"
#import "RotateMission.h"
#import "RoutMission.h"
#import "FirePacket.h"
#import "AttackResult.h"
#import "MeleePacket.h"
#import "SetMissionPacket.h"
#import "PlayerPingPacket.h"
#import "PlayerPongPacket.h"

#define SAVED_FIRE_PACKETS 50

@interface UdpNetworkHandler () {
    // last received packet id for all UDP data types
    unsigned int lastReceivedPacketId[7];

    // last received fire packets
    unsigned int lastCombatPackets[ SAVED_FIRE_PACKETS ];

    // next index
    unsigned int nextCombatPacketIndex;

    // the number of skipped and late packets
    unsigned int skippedPackets;
    unsigned int latePackets;
}

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic, strong) NSString *server;
@property (nonatomic, assign) unsigned short port;
@property (nonatomic, assign) BOOL receivingStarted;
@property (nonatomic, assign) BOOL actionStarted;
//@property (nonatomic, readwrite) unsigned int lastReceivedPacketId;
@property (nonatomic, weak) id<UdpNetworkHandlerDelegate> delegate;

@end


@implementation UdpNetworkHandler

- (instancetype) initWithServer:(NSString *)server port:(unsigned short)port delegate:(id<UdpNetworkHandlerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.server = server;
        self.port = port;
        self.receivingStarted = NO;
        self.actionStarted = NO;
        self.delegate = delegate;

        for ( unsigned int index = 0; index < 7; ++index ) {
            lastReceivedPacketId[index] = 0;
        }

        // no packets yet received
        for ( unsigned int index = 0; index < SAVED_FIRE_PACKETS; ++index ) {
            lastCombatPackets[index] = 0;
        }

        // no fire packets received yet
        nextCombatPacketIndex = 0;
        skippedPackets = 0;
        latePackets = 0;

        // create the socket
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    return self;
}


- (void) dealloc {
    NSLog( @"in" );
}


- (void) disconnect {
    if (self.udpSocket) {
        NSLog( @"disconnecting UDP socket" );

        // no more ping updates
        [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];

        // get rid of the socket
        self.udpSocket = nil;
    }

    // no more pings
    [[[CCDirector sharedDirector] scheduler] unscheduleAllForTarget:self];
}


- (void) sendPingToServer {
    [self sendUdpPacket:[ServerPingPacket new]];
}


- (void) sendPingToPlayer {
    [self sendUdpPacket:[PlayerPingPacket new]];
}


- (void) sendMissions:( NSMutableArray *)units {
    [self sendUdpPacket:[[MissionPacket alloc] initWithUnits:units]];
}


- (void) sendSetMission:(MissionType)mission forUnit:(Unit *)unit {
    [self sendUdpPacket:[[SetMissionPacket alloc] initWitUnit:unit mission:mission]];
}


- (void) sendUnitStats:( NSMutableArray *)units {
    [self sendUdpPacket:[[UnitStatsPacket alloc] initWithUnits:units]];
}


- (void) sendSmoke:( NSMutableArray *)smoke {
    [self sendUdpPacket:[[SmokePacket alloc] initWithSmoke:smoke]];
}


- (void) sendFireWithAttacker:(Unit *)attacker casualties:( NSMutableArray *)casualties hitPosition:(CGPoint)hitPosition {
    FirePacket * packet = [[FirePacket alloc] initWithAttacker:attacker
                                                    casualties:casualties
                                                   hitPosition:hitPosition];
    // send the packet twice!
    [self sendUdpPacket:packet];
    [self sendUdpPacket:packet];
}


- (void) sendMeleeWithAttacker:(Unit *)attacker target:(Unit *)target message:(AttackMessageType)message casualties:(int)casualties
            targetMoraleChange:(float)targetMoraleChange {
    [self sendUdpPacket:[[MeleePacket alloc] initWithAttacker:attacker
                                                       target:target
                                                      message:message
                                                   casualties:casualties
                                           targetMoraleChange:targetMoraleChange]];
}


- (void) sendUdpPacket:(UdpPacket *)packet {
    NSLog( @"sending packet %@", packet );
    [self.udpSocket sendData:packet.data toHost:self.server port:self.port withTimeout:-1 tag:0];

    // start receiving when we send the first packet
    if (!self.receivingStarted) {
        NSError *error = nil;
        if (![self.udpSocket beginReceiving:&error]) {
            NSLog( @"failed to begin receiving on UDP socket: %@", error );
        }

        self.receivingStarted = YES;
    }
}


//***************************************************************************************************************
#pragma mark - UDP socket delegate

- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    const UInt8 *bytes = [data bytes];

    // copy data
    unsigned char packetType = bytes[0];

    //NSLog( @"received packet: %@, size: %d bytes", [UdpPacket name:packetType], data.length );

    // skip packet type
    bytes++;

    switch (packetType) {
        case kUdpPongPacket:
            [self handlePong:bytes];
            break;

        case kStartActionPacket:
            [self handleActionStarted];
            break;

        case kUdpDataPacket:
            [self handleData:bytes];
            break;

        default:
            // unknown packet
            NSLog( @"unknown packet: %@ (%d)", [UdpPacket name:packetType], packetType );
            break;
    }
}


//****************************************************************************************************************************************
// UDP packet handlers
//****************************************************************************************************************************************

- (void) handleActionStarted {
    // there will be a few of these packets for redundancy when the game starts, so only handle the first one
    if ( ! self.actionStarted ) {
        self.actionStarted = YES;

        NSLog( @"game action started" );
        // prepare the game layer
        [[Globals sharedInstance].gameLayer startOnlineGame];

        // start the engine ticking
        [[Globals sharedInstance].engine start];

        // start sending a ping every few seconds
        [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector( sendPingToServer ) forTarget:self interval:2.0 paused:NO];
        [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector( sendPingToPlayer ) forTarget:self interval:2.0 paused:NO];
    }
}


- (void) handlePong:(const UInt8 *)data {
    unsigned short offset = 0;

    clock_t now = clock();
    clock_t then;

    // copy data
    memcpy( &then, data + offset, sizeof( clock_t ) );
    then = ntohl( then );

    // duration in milliseconds
    double milliseconds = ((double) (now - then)) / CLOCKS_PER_SEC * 1000.0;
    NSLog( @"roundtrip time to server: %.0f ms", milliseconds );

    if (self.delegate && [self.delegate respondsToSelector:@selector( serverPongReceived: )]) {
        [self.delegate serverPongReceived:milliseconds];
    }
}


- (void) handleData:(const UInt8 *)data {
    unsigned short offset = 0;

    // the real content type
    UdpNetworkPacketSubType subType = (UdpNetworkPacketSubType) data[offset++];

    // packet id
    unsigned int packetId = readInt32FromBuffer( data, &offset );

    // error statistics
    if ( packetId < lastReceivedPacketId[subType] ) {
        latePackets++;
    }

    // have we missed one packet in between?
    if ( packetId > lastReceivedPacketId[subType] + 1 ) {
        skippedPackets++;
    }

    // have we received an old packet?
    if ( subType == kFirePacket || subType == kMeleePacket ) {
        // a combat packet of some form, have we already received this packet?
        for ( unsigned int index = 0; index < SAVED_FIRE_PACKETS; ++index ) {
            if (lastCombatPackets[index] == packetId) {
                NSLog( @"duplicate packet %@ with id %d received, ignoring", [UdpPacket subName:subType], packetId );
                return;
            }
        }

        // a new packet, save this
        lastCombatPackets[ nextCombatPacketIndex++ ] = packetId;
    }
    else {
        // a non combat packet, is it too old?
        if (packetId <= lastReceivedPacketId[subType]) {
            NSLog( @"old non fire packet %d for type %@ received, last handled is %d", packetId, [UdpPacket subName:subType], lastReceivedPacketId[subType] );
            return;
        }
    }

    // new last received packet id
    lastReceivedPacketId[subType] = packetId;

    NSLog( @"last handled packet of type %@ is %d, skipped: %d, late: %d", [UdpPacket subName:subType], packetId, skippedPackets, latePackets );

    switch (subType) {
        case kMissionPacket:
            [self handleMissions:data + offset];
            break;

        case kUnitStatsPacket:
            [self handleUnitStats:data + offset];
            break;

        case kFirePacket:
            [self handleFire:data + offset packetId:packetId];
            break;

        case kMeleePacket:
            [self handleMelee:data + offset];
            break;

        case kSetMissionPacket:
            [self handleSetMission:data + offset];
            break;

        case kPlayerPingPacket:
            [self handlePlayerPing:data + offset];
            break;

        case kPlayerPongPacket:
            [self handlePlayerPong:data + offset];
            break;

        case kSmokePacket:
            [self handleSmoke:data + offset];
            break;
    }
}


- (void) handleMissions:(const UInt8 *)data {
    unsigned short offset = 0;
    unsigned short unitId;

    // number of units
    unsigned char unitCount = data[offset++];

    NSLog( @"received missions for %d enemy units", unitCount );

    for (unsigned int index = 0; index < unitCount; ++index) {
        // unit id
        unitId = readInt16FromBuffer( data, &offset );

        // mission type
        MissionType missionType = (MissionType) data[offset++];

        // find the unit
        Unit *unit = [self getEnemyUnit:unitId];
        if (unit == nil) {
            NSLog( @"***** received mission %d for unknown unit %d *****", missionType, unitId );
            return;
        }

        // create the mission
        unit.mission = [self createMission:missionType];
        //NSLog( @"received mission %@ for %@", unit.mission, unit );
    }
}


- (void) handleUnitStats:(const UInt8 *)data {
    unsigned short offset = 0;
    unsigned short unitId;
    unsigned char men, ammo;
    UnitMode mode;
    MissionType missionType;
    float morale, fatigue, x, y, rotation;

    // number of units
    unsigned char unitCount = data[offset++];

    NSLog( @"received stats for %d enemy units", unitCount );

    for (unsigned int index = 0; index < unitCount; ++index) {
        // unit id
        unitId = readInt16FromBuffer( data, &offset );

        // men, mode, mission, morale, fatigue
        men = data[offset++];
        mode = (UnitMode) data[offset++];
        missionType = (MissionType) data[offset++];
        morale = (float) data[offset++];
        fatigue = (float) data[offset++];
        ammo = data[offset++];

        // x, y, rotation
        x = readInt16FromBuffer( data, &offset ) / 10.0f;
        y = readInt16FromBuffer( data, &offset ) / 10.0f;
        rotation = readInt16FromBuffer( data, &offset ) / 10.0f;

        // find the affected unit
        Unit *unit = [self getEnemyUnit:unitId];
        if (unit == nil) {
            NSLog( @"***** received unit stats for unknown unit %d *****", unitId );
            return;
        }

        //NSLog( @"received stats for unit: %@, men %d, mode: %d, mission: %d, morale: %.1f, fatigue: %.1f, pos: %.0f, %.0f, rotation: %.1f",
        //        unit, men, mode, missionType, morale, fatigue, x, y, rotation );

        unit.men = men;
        unit.mode = mode;
        unit.weapon.ammo = ammo;
        unit.morale = morale;
        unit.fatigue = fatigue;

        // perform smooth moves and turns if required
        if ((int) unit.position.x != (int) x || (int) unit.position.y != (int) y) {
            [unit smoothMoveTo:ccp( x, y )];
        }

        if ((int) unit.rotation != (int) rotation) {
            [unit smoothTurnTo:rotation];
        }

        // create the mission if needed
        if (unit.mission.type != missionType) {
            unit.mission = [self createMission:missionType];
        }
    }
}


- (void) handleFire:(const UInt8 *)data packetId:(unsigned int)packetId {
    unsigned short offset = 0;
    unsigned short attackerId = readInt16FromBuffer( data, &offset );
    float hitX = readInt16FromBuffer( data, &offset ) / 10.0f;
    float hitY = readInt16FromBuffer( data, &offset ) / 10.0f;
    unsigned char count = data[offset++];

    Unit *attacker = [self getEnemyUnit:attackerId];
    NSLog( @"%@ (%d) fires at %.0f, %.0f", attacker, attackerId, hitX, hitY );

    // any casualties at all? if 0 then this is a smoke thing
    if ( count > 0 ) {
         NSMutableArray *allCasualties = [ NSMutableArray array];

        // read all casualties
        for (unsigned int index = 0; index < count; ++index) {
            unsigned short targetId = readInt16FromBuffer( data, &offset );
            unsigned char casualties = data[offset++];
            AttackMessageType messageType = (AttackMessageType) data[offset++];
            float targetMoraleChange = readInt16FromBuffer( data, &offset ) / 10.0f;

            // find the own unit that was hit
            Unit *target = [self getOwnUnit:targetId];
            if (!target) {
                NSLog( @"target %d not found, simulator issue? ignoring", targetId );
                continue;
            }

            NSLog( @"target %@ loses %d men, message: %d, target morale: %.1f", target, casualties, messageType, targetMoraleChange );

            // does the unit rout?
            RoutMission *routMission = nil;
            if (messageType & kDefenderRouted && target.mission.type != kRoutMission) {
                if ((routMission = [CombatMission routUnit:target]) == nil) {
                    NSLog( @"could not find a rout position!" );
                }
            }

            // add a result
            [allCasualties addObject:[[AttackResult alloc] initWithMessage:messageType withAttacker:attacker forTarget:target casualties:casualties
                                                               routMission:routMission targetMoraleChange:targetMoraleChange attackerMoraleChange:0]];
        }
        // create and show a visualization immediately
        AttackVisualization *visualization = [[AttackVisualization alloc] initWithAttacker:attacker casualties:allCasualties hitPosition:ccp( hitX, hitY )];
        [visualization execute];
    }
    else {
        // we're creating smoke
        AttackVisualization *visualization = [[AttackVisualization alloc] initWithAttacker:attacker smokePosition:ccp( hitX, hitY )];
        [visualization execute];
    }
    
    // TODO: verify the thread as we now create UI stuff!
    
}


- (void) handleMelee:(const UInt8 *)data {
    unsigned short offset = 0;

    unsigned short attackerId = readInt16FromBuffer( data, &offset );
    unsigned short targetId = readInt16FromBuffer( data, &offset );
    AttackMessageType messageType = (AttackMessageType) data[offset++];
    unsigned char casualties = data[offset++];
    float targetMoraleChange = readInt16FromBuffer( data, &offset ) / 10.0f;

    Unit *attacker = [self getEnemyUnit:attackerId];
    Unit *target = [self getOwnUnit:targetId];
    NSLog( @"%@ melees with %@, lost %d men", attacker, target, casualties );

    // does the unit rout?
    RoutMission *routMission = nil;
    if (messageType & kDefenderRouted && target.mission.type != kRoutMission) {
        NSLog( @"target %@ routs", target );
        if ((routMission = [CombatMission routUnit:target]) == nil) {
            NSLog( @"could not find a rout position!" );
        }
    }

    // add a result
    AttackResult *result = [[AttackResult alloc] initWithMessage:messageType withAttacker:attacker forTarget:target casualties:casualties
                                                     routMission:routMission targetMoraleChange:targetMoraleChange attackerMoraleChange:0];
    [result execute];
}


- (void) handleSetMission:(const UInt8 *)data {
    unsigned short offset = 0;

    // unit id
    unsigned short unitId = readInt16FromBuffer( data, &offset );

    // mission type
    MissionType missionType = (MissionType) data[offset++];

    // find the unit
    Unit *unit = [self getOwnUnit:unitId];
    if (unit == nil) {
        NSLog( @"***** received mission %d for unknown unit %d *****", missionType, unitId );
        return;
    }

    // same mission as before?
    if ( unit.mission.type != missionType ) {
        // create the mission
        unit.mission = [self createMission:missionType];
        NSLog( @"setting mission %@ for %@", unit.mission, unit );
    }
}


- (void) handlePlayerPing:(const UInt8 *)data {
    unsigned short offset = 0;

    NSLog( @"sending response to a player ping" );

    clock_t ms = readInt32FromBuffer( data, &offset );
    [self sendUdpPacket:[[PlayerPongPacket alloc] initWithTime:ms]];
}


- (void) handlePlayerPong:(const UInt8 *)data {
    unsigned short offset = 0;

    clock_t now = clock();

    clock_t then = readInt32FromBuffer( data, &offset );

    // duration in milliseconds
    double milliseconds = ((double) (now - then)) / CLOCKS_PER_SEC * 1000.0;
    NSLog( @"roundtrip time to player: %.0f ms", milliseconds );

    if (self.delegate && [self.delegate respondsToSelector:@selector( playerPongReceived: )]) {
        [self.delegate playerPongReceived:milliseconds];
    }
}


- (void) handleSmoke:(const UInt8 *)data {
    unsigned short offset = 0;

    // number of smokes
    unsigned short count = readInt16FromBuffer( data, &offset );

    Globals * globals = [Globals sharedInstance];
    PlayerId enemyPlayerId = globals.localPlayer.playerId == kPlayer1 ? kPlayer2 : kPlayer1;

     NSMutableArray * enemySmoke = enemyPlayerId == kPlayer2 ? globals.map.smoke2 : globals.map.smoke1;

    // add smoke if needed
    if ( enemySmoke.count < count ) {
        while ( enemySmoke.count < count ) {
            [globals.map addSmoke:ccp(0, 0) forPlayer:enemyPlayerId];
        }
    }

    // remove smoke if needed
    if ( enemySmoke.count > count ) {
        while ( enemySmoke.count > count ) {
            Smoke * remove = [enemySmoke lastObject];
            [enemySmoke removeLastObject];
            [remove removeFromParentAndCleanup:YES];
        }
    }

    // now we have exactly as much smoke as needed, loop and update the smoke we have with the given parameters
    for (unsigned int index = 0; index < count; ++index) {
        float x = readInt16FromBuffer( data, &offset ) / 10.0f;
        float y = readInt16FromBuffer( data, &offset ) / 10.0f;
        unsigned char opacity = data[offset++];

        Smoke * updated = [enemySmoke objectAtIndex:index];
        updated.position = ccp( x, y );
        updated.opacity = opacity;
    }
}


- (Unit *) getEnemyUnit:(unsigned short)unitId {
    // find among the enemies
     NSMutableArray *units = [Globals sharedInstance].localPlayer.playerId == kPlayer1 ? [Globals sharedInstance].unitsPlayer2 : [Globals sharedInstance].unitsPlayer1;

    for (Unit *tmp in units) {
        if (tmp.unitId == unitId) {
            return tmp;
        }
    }

    return nil;
}


- (Unit *) getOwnUnit:(unsigned short)unitId {
    // find among own units
     NSMutableArray *units = [Globals sharedInstance].localUnits;

    for (Unit *tmp in units) {
        if (tmp.unitId == unitId) {
            return tmp;
        }
    }

    return nil;
}


- (Mission *) createMission:(MissionType)type {
    Mission *mission = nil;
    switch (type) {
        case kAdvanceMission:
            mission = [AdvanceMission new];
            break;
        case kAssaultMission:
            mission = [AssaultMission new];
            break;
        case kFireMission:
            mission = [FireMission new];
            break;
        case kAreaFireMission:
            mission = [AreaFireMission new];
            break;
        case kSmokeMission:
            mission = [SmokeMission new];
            break;
        case kMeleeMission:
            mission = [MeleeMission new];
            break;
        case kMoveMission:
            mission = [MoveMission new];
            break;
        case kMoveFastMission:
            mission = [MoveFastMission new];
            break;
        case kRetreatMission:
            mission = [RetreatMission new];
            break;
        case kRotateMission:
            mission = [RotateMission new];
            break;
        case kScoutMission:
            mission = [ScoutMission new];
            break;
        case kChangeModeMission:
            mission = [ChangeModeMission new];
            break;
        case kDisorganizedMission:
            mission = [DisorganizedMission new];
            break;
        case kIdleMission:
            mission = [IdleMission new];
            break;
        case kRoutMission:
            mission = [RoutMission new];
            break;
        case kRallyMission:
            mission = [RallyMission new];
            break;
    }

    NSAssert( mission, @"invalid mission type" );

    return mission;
}
@end
