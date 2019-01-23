
#import "CCBReader.h"

#import "PhotonSetupGame.h"
#import "PhotonHostRoom.h"
#import "Globals.h"
#import "Scenario.h"

@interface PhotonSetupGame ()

@property (nonatomic, strong) CCScene *  sceneToCreate;
@end


@implementation PhotonSetupGame

@synthesize backButton;
@synthesize smallButton;
@synthesize mediumButton;
@synthesize largeButton;
@synthesize messagePaper;
@synthesize buttonsPaper;


+ (CCScene *) node {
   return [CCBReader sceneWithNodeGraphFromFile:@"PhotonSetupGame.ccb"];
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
    self.messagePaper.position = ccp( -200, 300 );
    self.messagePaper.rotation = 30;
    self.messagePaper.scale = 2.0f;

    self.buttonsPaper.position = ccp( 1000, -200 );
    self.buttonsPaper.rotation = -30;
    self.buttonsPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.messagePaper toPos:ccp(250, 415) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:-3 inTime:0.5f atRate:0.5f];

    [self moveNode:self.buttonsPaper toPos:ccp(750, 355) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.buttonsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.buttonsPaper toAngle:4 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];
    [self addAnimatableNode:self.buttonsPaper];
}


- (void) small {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kSmallBattle];

    self.sceneToCreate = [PhotonHostRoom node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) medium {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kMediumBattle];

    self.sceneToCreate = [PhotonHostRoom node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) large {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self findScenario:kLargeBattle];

    self.sceneToCreate = [PhotonHostRoom node];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) findScenario:(BattleSizeType)battleSize {
    // all matching scenarios
    NSMutableArray * suitable = [NSMutableArray new];

    // save the size as the desired battle size
    [Globals sharedInstance].onlineGameSize = battleSize;

    // check them all
    for ( Scenario * scenario in [Globals sharedInstance].multiplayerScenarios ) {
        if ( battleSize == kNotIncluded || scenario.battleSize == battleSize ) {
            // found one
            [suitable addObject:scenario];
        }
    }

    CCLOG( @"found %lu suitable scenarios", (unsigned long)suitable.count );

    // randomly get one
    [Globals sharedInstance].scenario = suitable[ arc4random_uniform( (unsigned int)suitable.count ) ];

    CCLOG( @"selected scenario %@", [Globals sharedInstance].scenario.title );
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // ask the user for confirmation
    [self askQuestion:@"Do you want to cancel and abandon the game?" withTitle:@"Confirm" okText:@"Yes" cancelText:@"No" delegate:self];
}


- (void) questionAccepted {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) questionRejected {
    // proceed as normal
    CCLOG( @"in" );
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
