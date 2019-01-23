#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "ResetCampaign.h"
#import "Globals.h"
#import "Utils.h"
#import "SelectScenario.h"
#import "Scenario.h"

@implementation ResetCampaign

@synthesize resetButton;
@synthesize backButton;
@synthesize infoPaper;


+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"ResetCampaign.ccb"];
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Reset" forButton:self.resetButton];
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
    [self animateNodesAwayAndShowScene:[SelectScenario node]];
}


- (void) reset {
    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    int campaignId = globals.campaignId;
    for ( Scenario * scenario in globals.scenarios ) {
        if ( scenario.scenarioType == kCampaign ) {
            [scenario clearCompletedForCampaign:campaignId];
        }
    }

    // disable back button
    [self disableBackButton:self.backButton];
    [self animateNodesAwayAndShowScene:[SelectScenario node]];
}

@end
