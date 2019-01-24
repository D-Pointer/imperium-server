

#import "Globals.h"
#import "AI.h"
#import "MapLayer.h"
#import "GameLayer.h"
#import "Engine.h"
#import "GameInput.h"
#import "UdpNetworkHandler.h"
#import "Army.h"
#import "GameCenter.h"
#import "ParameterHandler.h"

@implementation Globals

- (id) init {
	if( (self = [super init])) {
        // some global data
        self.units         = [CCArray array];
        self.unitsPlayer1  = [CCArray array];
        self.unitsPlayer2  = [CCArray array];
        self.objectives    = [CCArray array];
        self.organizations = [CCArray array];
        self.scenarios     = [CCArray array];
        self.multiplayerScenarios = [CCArray array];
        self.selection     = [Selection new];
        self.scores        = [ScoreCounter new];
        self.audio         = [Audio new];
        self.engine        = [Engine new];
        self.input         = [GameInput new];
        self.parameterHandler = [ParameterHandler new];

        // set later
        self.appDelegate   = nil;
        self.player1       = nil;
        self.player2       = nil;
        self.localPlayer   = nil;
        self.gameType      = kSinglePlayerGame;

        // these are set by someone else
        self.clock       = nil;
        self.scenario    = nil;
        self.scenarioScript = nil;
        self.mapLayer    = nil;
        self.gameLayer   = nil;
        self.tutorial    = nil;
        self.pathFinder  = nil;
        self.actionsMenu = nil;
        self.tcpConnection = nil;
        self.udpConnection = nil;
        self.ai          = nil;
        self.lineOfSight = nil;
        self.onlineGame  = nil;
    }
    
	return self;    
}


+ (Globals *) sharedInstance {
    static Globals * globalsInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once( &onceToken, ^{
        globalsInstance = [[Globals alloc] init];
    });
    
	// return the instance
	return globalsInstance;
}


- (void) reset {
    CCLOG( @"in" );
    
    // reset game specific data
    self.player1        = nil;
    self.player2        = nil;
    self.localPlayer    = nil;
    self.scenario       = nil;
    self.scenarioScript = nil;
    self.clock          = nil;
    self.tutorial       = nil;
    self.pathFinder     = nil;
    self.ai             = nil;
    self.lineOfSight    = nil;
    self.onlineGame     = nil;

    // back at the setup phase
    self.gameType = kSinglePlayerGame;

    if ( self.actionsMenu ) {
        [self.actionsMenu removeFromParentAndCleanup:YES];
        self.actionsMenu = nil;
    }

    if ( self.mapLayer ) {
        [self.mapLayer removeFromParentAndCleanup:YES];
        self.mapLayer = nil;
    }

    if ( self.gameLayer ) {
        [self.gameLayer reset];
        [self.gameLayer removeFromParentAndCleanup:YES];
        self.gameLayer = nil;
    }

    // clear containers
    [self.units removeAllObjects];
    [self.unitsPlayer1 removeAllObjects];
    [self.unitsPlayer2 removeAllObjects];
    [self.objectives removeAllObjects];
    [self.organizations removeAllObjects];

    // reset some data
    [self.selection reset];

    // new engine and input
    if ( self.engine ) {
        [self.engine stop];
    }
    self.engine = [Engine new];
    self.input  = [GameInput new];

    // networking
    if ( self.udpConnection ) {
        [self.udpConnection disconnect];
        self.udpConnection = nil;
    }

    // load the armies
    [Army loadArmies];

    // not touched:
    // self.scenarios
    // self.multiplayerScenarios
    // self.ai
    // self.scores
    // self.audio
    // self.tcpConnection
    // self.updConnection
}

@end
