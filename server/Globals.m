

#import "Globals.h"
#import "Smoke.h"
#import "Map.h"
#import "Engine.h"
#import "UdpNetworkHandler.h"
#import "Army.h"
#import "ParameterHandler.h"

@implementation Globals

- (id) init {
	if( (self = [super init])) {
        // some global data
        self.units         = [ NSMutableArray array];
        self.unitsPlayer1  = [ NSMutableArray array];
        self.unitsPlayer2  = [ NSMutableArray array];
        self.objectives    = [ NSMutableArray array];
        self.organizations = [ NSMutableArray array];
        self.smoke         = [ NSMutableArray array];
        self.scores        = [ScoreCounter new];
        self.engine        = [Engine new];
        self.parameterHandler = [ParameterHandler new];

        // set later
        self.player1       = nil;
        self.player2       = nil;

        // these are set by someone else
        self.clock       = nil;
        self.scenario    = nil;
        self.pathFinder  = nil;
        self.tcpConnection = nil;
        self.udpConnection = nil;
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
    NSLog( @"in" );
    
    // reset game specific data
    self.player1        = nil;
    self.player2        = nil;
    self.scenario       = nil;
    self.map            = nil;
    self.clock          = nil;
    self.pathFinder     = nil;
    self.lineOfSight    = nil;
    self.onlineGame     = nil;

    // clear containers
    [self.units removeAllObjects];
    [self.unitsPlayer1 removeAllObjects];
    [self.unitsPlayer2 removeAllObjects];
    [self.objectives removeAllObjects];
    [self.organizations removeAllObjects];
    [self.smoke removeAllObjects];

    // new engine and input
    if ( self.engine ) {
        [self.engine stop];
    }
    self.engine = [Engine new];

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
