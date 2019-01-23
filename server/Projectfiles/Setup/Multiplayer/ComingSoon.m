#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "ComingSoon.h"
#import "Globals.h"
#import "Utils.h"
#import "MainMenu.h"

@implementation ComingSoon

@synthesize backButton;
@synthesize infoPaper;


+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"ComingSoon.ccb"];
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.infoPaper.position = ccp( 1200, 300 );
    self.infoPaper.rotation = -50;
    self.infoPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.infoPaper toPos:ccp( 512, 400 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.infoPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.infoPaper toAngle:3 inTime:0.5f atRate:0.5f];

    // these can be animated
    [self addAnimatableNode:self.infoPaper];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    [self animateNodesAwayAndShowScene:[MainMenu node]];
}

@end
