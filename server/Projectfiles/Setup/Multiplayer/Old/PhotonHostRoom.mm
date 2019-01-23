
#import "CCBReader.h"

#import "PhotonHostRoom.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "GameCenter.h"
#import "Scenario.h"
#import "NetworkLogic.h"
#import "EditArmy.h"


@implementation PhotonHostRoom

@synthesize backButton;
@synthesize paper;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"PhotonHostRoom.ccb"];
}


- (void) didLoadFromCCB {
    Globals * globals = [Globals sharedInstance];

    // first set us as the Photon delegate
    globals.photon.delegate = self;

    // keep these here so that we can create the room properties below and refer to them
    static int scenarioId = globals.scenario.scenarioId;
    static int battleSize = globals.scenario.battleSize;

    // all custom room properties
    NSDictionary * roomProperties = @{ @"scenarioId"   : [NSValue value:&scenarioId withObjCType:@encode(int)],
                                       @"scenarioName" : globals.scenario.title,
                                       @"battleSize"   : [NSValue value:&battleSize withObjCType:@encode(int)],
                                       @"playerName"   : globals.gameCenter.localPlayerName };

    EGArray * filters = [EGArray arrayWithObjects:@"scenarioId", @"scenarioName", @"battleSize", @"playerName", nil];

    // try to join a random room that matches the properties
    [globals.photon createRoom:roomProperties withFilters:filters];

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    // these can be animated
    [self addAnimatableNode:self.paper];
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

    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) questionRejected {
    // proceed as normal
    CCLOG( @"in" );
}


- (void) animationsDone {
    // pop off this scene
    [[CCDirector sharedDirector] popScene];
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
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kNetworkPlayer];
    globals.localPlayer = globals.player1;

    // time to purchase forces
    [[CCDirector sharedDirector] replaceScene:[MultiplayerForces node]];
}


// ------------------------------------------------------------------------------------------------------------------------
#pragma mark - Network Logic Delegate


- (void) joinRoomSucceeded {
    CCLOG( @"joining room succeeded" );
}


- (void) joinRoomFailed {
    CCLOG( @"joining room failed" );
}


- (void) roomCreationSucceeded:(NSDictionary *)properties {
    CCLOG( @"room created ok, properties: %@", properties );
}


- (void) roomCreationFailed:(NSDictionary *)properties {
    CCLOG( @"failed to create room with properties: %@", properties );

    // TODO: show error
}


- (void) playerJoinedRoom {
    EGLoadBalancingRoom * room = [Globals sharedInstance].photon.currentRoom;

    if ( ! room  ) {
        CCLOG( @"player joined, but no current room?" );
        return;
    }

    CCLOG( @"player joined room %@, now %d players", room.Name, room.PlayerCount );

    // enough players?
    if ( room.PlayerCount == 2 ) {
        CCLOG( @"enough players, game ready" );

        // find scenario id
        int scenarioId;
        [[room.CustomProperties objectForKey:@"scenarioId"] getValue:&scenarioId];
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
