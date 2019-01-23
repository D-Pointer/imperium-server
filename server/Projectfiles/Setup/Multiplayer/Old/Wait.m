
#import "CCBReader.h"

#import "Wait.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "ResumeGame.h"
#import "BonjourParameters.h"
#import "Connection.h"
#import "Scenario.h"
#import "GameCenter.h"
#import "EditArmy.h"

@interface Wait ()

@property (nonatomic, strong) BonjourServer * bonjourServer;

@end


@implementation Wait

@synthesize backButton;

+ (id) node {
    Wait * node = (Wait *)[CCBReader nodeGraphFromFile:@"Wait.ccb"];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    NSString * bonjourName;
    
    // are we signed in to game center?
    if ( [Globals sharedInstance].gameCenter.isAuthenticated ) {
        bonjourName = [NSString stringWithFormat:@"%@ - %@", [Globals sharedInstance].gameCenter.localPlayerName, [Globals sharedInstance].scenario.title];
    }
    else {
        // use the scenario name as the bonjour name
        bonjourName = [Globals sharedInstance].scenario.title;
    }
    
    // create the bonjour server
    self.bonjourServer = [[BonjourServer alloc] initWithDomain:BONJOUR_DOMAIN type:BONJOUR_TYPE name:bonjourName];
    self.bonjourServer.delegate = self;

    // start it
    [self.bonjourServer start];

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [[CCDirector sharedDirector] popScene];     
}


// ------------------------------------------------------------------------------------------------------------------------
#pragma mark - Bonjour Server Delegate

- (void) clientConnected:(GCDAsyncSocket *)socket {
    CCLOG( @"%@", socket );

    // create the global socket connection
    [Globals sharedInstance].connection = [[Connection alloc] initWithSocket:socket];

    // stop listening for more players
    [self.bonjourServer stop];
    self.bonjourServer.delegate = nil;
    self.bonjourServer = nil;

    // send the scenario id
    int scenarioId = [Globals sharedInstance].scenario.scenarioId;
    NSData * scenarioIdData = [NSData dataWithBytes:&scenarioId length: sizeof(scenarioId)];
    //[[Globals sharedInstance].connection sendMessage:kScenarioIdMessage withData:scenarioIdData];

    CCLOG( @"sending scenario id: %d", scenarioId );

    // time to purchase forces
    [[CCDirector sharedDirector] replaceScene:[MultiplayerForces node]];
}

@end
