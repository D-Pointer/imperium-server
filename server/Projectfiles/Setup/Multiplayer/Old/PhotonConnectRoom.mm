
#import "CCBReader.h"

#import "PhotonConnectRoom.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "ResumeGame.h"
#import "Scenario.h"
#import "NetworkLogicDelegate.h"
#import "EditArmy.h"
#import "NetworkLogic.h"

@interface PhotonConnectRoom ()

@property (nonatomic, strong) NSMutableArray * games;
@property (nonatomic, strong) NSMutableArray * labels;
@property (nonatomic, strong) CCMenu *         clientMenu;
@property (nonatomic, strong) NSMutableDictionary * roomMapping;
@property (nonatomic, strong) CCScene *        sceneToCreate;

@end


@implementation PhotonConnectRoom

@synthesize menu;
@synthesize gamesPaper;
@synthesize backButton;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"PhotonConnectRoom.ccb"];
}


- (void) didLoadFromCCB {
    self.labels = [NSMutableArray new];
    self.roomMapping = [NSMutableDictionary new];
    self.sceneToCreate = nil;

    Globals * globals = [Globals sharedInstance];

    // first set us as the Photon delegate
    globals.photon.delegate = self;

    // set up the rooms we know of so far
    [self roomsChanged:globals.photon.rooms];

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    // these can be animated
    [self addAnimatableNode:self.gamesPaper];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // ask the user for confirmation
    [self askQuestion:@"Do you want to cancel and abandon the game?" withTitle:@"Confirm" okText:@"Yes" cancelText:@"No" delegate:self];
}


- (void) questionAccepted {
    CCLOG( @"in" );

    // we're no longer a delegate
    [Globals sharedInstance].photon.delegate = nil;

    // leave any rooms
    [[Globals sharedInstance].photon leaveRoom];

    self.sceneToCreate = nil;
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) questionRejected {
    // proceed as normal
    CCLOG( @"in" );
}


- (void) gameSelected:(id)sender {
    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    int scenarioId = ((CCMenuItemLabel *)sender).tag;

    CCLOG( @"selected game: %d", scenarioId );

    // save the room into our room mapping
    NSString * roomName = self.roomMapping[ [NSNumber numberWithInt:scenarioId] ];

    // not found?
    if ( roomName == nil ) {
        CCLOG( @"room %d not found", scenarioId );
        return;
    }

    // attempt to join the room
    [[Globals sharedInstance].photon joinRoom:roomName];
}


- (void) loadScenario:(int)scenarioId {
    // load and start game
    CCLOG( @"loading scenario" );
    Globals * globals = [Globals sharedInstance];

    // first find the scenario
    globals.scenario = nil;
    for ( Scenario * scenario in globals.multiplayerScenarios ) {
        if ( scenario.scenarioId == scenarioId ) {
            // found it
            globals.scenario = scenario;
            break;
        }
    }

    if ( globals.scenario == nil ) {
        // show an error scene
        [self showErrorScreen:@"Did not find selected battle!\nPlease update the game on both devices."];
        CCLOG( @"did not find scenario with id: %d!", scenarioId );
        return;
    }

    // set up players. we're always player 2
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kNetworkPlayer];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kLocalPlayer];
    globals.localPlayer = globals.player2;

    // animate everything away
    self.sceneToCreate = [MultiplayerForces node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) animationsDone {
    if ( self.sceneToCreate == nil ) {
        [[CCDirector sharedDirector] popScene];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:self.sceneToCreate];
    }
}



// ------------------------------------------------------------------------------------------------------------------------
#pragma mark - Network Logic Delegate

- (void) roomsChanged:(NSArray *)rooms {
    // nuke any old menu
    if ( self.clientMenu ) {
        [self.clientMenu removeFromParentAndCleanup:YES];
    }

    [self.labels removeAllObjects];

    // precautions
    if ( rooms == nil || rooms.count == 0 ) {
        CCLOG( @"no rooms available" );
    }

    [self.roomMapping removeAllObjects];

    int y = 200;
    int scenarioId;

    // create new labels
    for ( EGLoadBalancingRoom * room in rooms ) {
        // extract all data
        NSString * title  = [room.CustomProperties objectForKey:@"scenarioName"];
        NSString * player = [room.CustomProperties objectForKey:@"playerName"];
        [[room.CustomProperties objectForKey:@"scenarioId"] getValue:&scenarioId];

        // the visual label
        CCLabelBMFont * label = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%@ - %@", player, title] fntFile:@"SetupFont.fnt"];

        // a menu item to hold the label
        CCMenuItemLabel * menuLabel = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(gameSelected:)];
        menuLabel.position = ccp( 150, y );
        menuLabel.tag = scenarioId;

        [self.labels addObject:menuLabel];
        y -= 45;

        // save the room into our room mapping
        self.roomMapping[ [NSNumber numberWithInt:scenarioId] ] = room.Name;
    }

    // create a new menu with all the labels
    self.clientMenu = [CCMenu menuWithArray:self.labels];
    self.clientMenu.position = ccp( 0, 0 );
    [self.gamesPaper addChild:self.clientMenu];
}


- (void) joinRoomSucceeded {
    CCLOG( @"joining room succeeded" );
}


- (void) joinRoomFailed {
    CCLOG( @"joining room failed" );
}


- (void) playerJoinedRoom {
    EGLoadBalancingRoom * room = [Globals sharedInstance].photon.currentRoom;

    if ( ! room  ) {
        CCLOG( @"player joined, but no current room?" );
        return;
    }

    CCLOG( @"player joined room %@, now %d players", room.Name, room.PlayerCount );

    int scenarioId;

    // extract all data
    NSString * title  = [room.CustomProperties objectForKey:@"scenarioName"];
    NSString * player = [room.CustomProperties objectForKey:@"playerName"];
    [[room.CustomProperties objectForKey:@"scenarioId"] getValue:&scenarioId];

    // enough players?
    if ( room.PlayerCount == 2 ) {
        CCLOG( @"enough players, game ready" );

        // load the scenario
        [self loadScenario:scenarioId];
    }
}


- (void) playerLeftRoom {
    EGLoadBalancingRoom * room = [Globals sharedInstance].photon.currentRoom;

    if ( ! room  ) {
        CCLOG( @"player left, but no current room?" );
        return;
    }

    CCLOG( @"player left room %@, now %d players", room.Name, room.PlayerCount );
}

@end
