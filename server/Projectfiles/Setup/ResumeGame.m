#import "CCBReader.h"

#import "ResumeGame.h"
#import "SelectScenario.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "Upgrade.h"

@interface ResumeGame ()

@property (nonatomic, strong) CCScene *sceneToCreate;
@property (nonatomic, strong) NSString *filename;
@end


@implementation ResumeGame

@synthesize backButton;
@synthesize resumeButton;
@synthesize startNewGameButton;
@synthesize messagePaper;
@synthesize buttonsPaper;

+ (CCScene *) node {
    ResumeGame *node = (ResumeGame *) [CCBReader nodeGraphFromFile:@"ResumeGame.ccb"];

    // wrap in a scene
    CCScene *scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    self.sceneToCreate = nil;
    self.filename = nil;

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Resume" forButton:self.resumeButton];
    [self createText:@"New game" forButton:self.startNewGameButton];
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
    [self moveNode:self.messagePaper toPos:ccp( 500, 440 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.messagePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.messagePaper toAngle:-3 inTime:0.5f atRate:0.5f];

    [self moveNode:self.buttonsPaper toPos:ccp( 570, 245 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.buttonsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.buttonsPaper toAngle:4 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.messagePaper];
    [self addAnimatableNode:self.buttonsPaper];
}


- (void) resume {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    self.filename = [NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId];

    [self animateNodesAwayWithSelector:@selector( animationsDone )];
}


- (void) newGame {
    CCLOG( @"in" );

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // delete the old saved games and create the new scene we push
    [GameSerializer deleteSavedGame:[NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId]];
    self.sceneToCreate = [SelectScenario node];

    [self animateNodesAwayWithSelector:@selector( animationsDone )];
}


- (void) back {
    // disable back button
    [self disableBackButton:self.backButton];

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector( animationsDone )];
}


- (void) animationsDone {
    // any new scene?
    if (self.sceneToCreate) {
        [[CCDirector sharedDirector] replaceScene:self.sceneToCreate];
        self.sceneToCreate = nil;
    }

    else if (self.filename) {
        if (![GameSerializer loadGame:self.filename]) {
            CCLOG( @"failed to load" );

            // show an upgrade screen
            [[CCDirector sharedDirector] replaceScene:[Upgrade node]];
        }
    }
    else {
        // back was pressed, just pop this off
        [[CCDirector sharedDirector] popScene];
    }
}


@end
