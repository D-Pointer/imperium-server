
#import "CCBReader.h"

#import "MultiplayerSetupGame.h"
#import "Globals.h"
#import "Scenario.h"
#import "EditArmy.h"


@interface MultiplayerSetupGame ()

@property (nonatomic, strong) CCScene *  sceneToCreate;
@end


@implementation MultiplayerSetupGame

@synthesize backButton;
@synthesize smallButton;
@synthesize mediumButton;
@synthesize largeButton;
@synthesize messagePaper;
@synthesize buttonsPaper;


+ (CCScene *) node {
   return [CCBReader sceneWithNodeGraphFromFile:@"MultiplayerSetupGame.ccb"];
}


- (void) didLoadFromCCB {
    self.sceneToCreate = nil;

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Small" forButton:self.smallButton];
    [self createText:@"Medium" forButton:self.mediumButton];
    [self createText:@"Large" forButton:self.largeButton];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.messagePaper.position = ccp( 1200, 300 );
    self.messagePaper.rotation = 30;
    self.messagePaper.scale = 2.0f;

    self.buttonsPaper.position = ccp( 100, -200 );
    self.buttonsPaper.rotation = -30;
    self.buttonsPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.messagePaper toPos:ccp(512, 460) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:-3 inTime:0.5f atRate:0.5f];

    [self moveNode:self.buttonsPaper toPos:ccp(512, 200) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.buttonsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.buttonsPaper toAngle:4 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];
    [self addAnimatableNode:self.buttonsPaper];
}


- (void) small {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kSmallBattle];

    self.sceneToCreate = [MultiplayerForces node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) medium {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kMediumBattle];

    self.sceneToCreate = [Wait node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) large {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kLargeBattle];

    self.sceneToCreate = [Wait node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) findScenario:(BattleSizeType)battleSize {
    // all matching scenarios
    NSMutableArray * suitable = [NSMutableArray new];

    // check them all
    for ( Scenario * scenario in [Globals sharedInstance].multiplayerScenarios ) {
        if ( scenario.battleSize == battleSize ) {
            // found one
            [suitable addObject:scenario];
        }
    }

    CCLOG( @"found %d suitable scenarios", suitable.count );

    // randomly get one
    [Globals sharedInstance].scenario = suitable[ arc4random_uniform( suitable.count ) ];

    CCLOG( @"selected scenario %@", [Globals sharedInstance].scenario.title );
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) animationsDone {
    // any new scene?
    if ( self.sceneToCreate ) {
        [[CCDirector sharedDirector] replaceScene:self.sceneToCreate];
        self.sceneToCreate = nil;
    }
    else {
        // back was pressed, just pop this off
        [[CCDirector sharedDirector] popScene];
    }
}


@end
