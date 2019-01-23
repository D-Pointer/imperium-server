
#import "CCBReader.h"

#import "PhotonMultiplayer.h"
#import "PhotonSetupGame.h"
#import "PhotonConnectRoom.h"
#import "Globals.h"
#import "MapReader.h"
#import "Scenario.h"

@interface PhotonMultiplayer ()

@property (nonatomic, strong) CCScene *  sceneToCreate;

@end


@implementation PhotonMultiplayer

@synthesize createGameButton;
@synthesize connectButton;
@synthesize backButton;
@synthesize messagePaper;
@synthesize buttonsPaper;

+ (id) node {
    PhotonMultiplayer * node = (PhotonMultiplayer *)[CCBReader nodeGraphFromFile:@"PhotonMultiplayer.ccb"];

    // wrap in a scene
    CCScene * scene = [CCScene node];
    [scene addChild:node];
    return scene;
}

- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"New Game" forButton:self.createGameButton];
    [self createText:@"Connect" forButton:self.connectButton];
    [self createText:@"Back" forButton:self.backButton];

    self.sceneToCreate = nil;

    Globals * globals = [Globals sharedInstance];

    // do we need to parse the multiplayer scenarios?
    if ( globals.multiplayerScenarios.count == 0 ) {
        // find all the scenarios
        NSString *scenarioDir  = [NSString stringWithFormat:@"%@/Scenarios/Multiplayer", [[NSBundle mainBundle] bundlePath]];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *dirContents   = [manager contentsOfDirectoryAtPath:scenarioDir error:nil];
        NSPredicate *filter    = [NSPredicate predicateWithFormat:@"self ENDSWITH '.map'"];
        NSArray *scenarioList  = [dirContents filteredArrayUsingPredicate:filter];

        for ( NSString * path in scenarioList ) {
            // parse the meta data
            Scenario * scenario = [[MapReader new] parseScenarioMetaData:[NSString stringWithFormat:@"%@/%@", scenarioDir, path]];
            NSAssert( scenario, @"invalid scenario" );
            [globals.multiplayerScenarios addObject:scenario];
        }

        CCLOG( @"parsed metadata for %lu multiplayer scenarios", (unsigned long)globals.multiplayerScenarios.count );
    }
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.messagePaper.position = ccp( -300, 100 );
    self.messagePaper.rotation = -50;
    self.messagePaper.scale = 2.0f;

    self.buttonsPaper.position = ccp( 900, -200 );
    self.buttonsPaper.rotation = 40;
    self.buttonsPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.messagePaper toPos:ccp(455, 505) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:4 inTime:0.5f atRate:0.5f];

    [self moveNode:self.buttonsPaper toPos:ccp(480, 300) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.buttonsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.buttonsPaper toAngle:-4 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];
    [self addAnimatableNode:self.buttonsPaper];
}


- (void) createGame {
    CCLOG( @"in" );
    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    // multiplayer game
    globals.gameType = kMultiplayerGame;

    // set up players when we know what players we have
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kNetworkPlayer];
    globals.localPlayer = globals.player1;

    // assume multiplayer games are never saved
    self.sceneToCreate = [PhotonSetupGame node];

    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) hostedGame {
    CCLOG( @"in" );
    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    // multiplayer game
    globals.gameType = kMultiplayerGame;

    // set up players when we know what players we have
    [Globals sharedInstance].player1 = [[Player alloc] initWithId:kPlayer1 type:kNetworkPlayer];
    [Globals sharedInstance].player2 = [[Player alloc] initWithId:kPlayer2 type:kLocalPlayer];
    [Globals sharedInstance].localPlayer = [Globals sharedInstance].player2;

    self.sceneToCreate = [PhotonConnectRoom node];

    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
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


@end
