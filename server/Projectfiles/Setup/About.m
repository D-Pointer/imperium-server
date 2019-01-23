
#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "About.h"
#import "Globals.h"

@implementation About

@synthesize version;
@synthesize versionName;
@synthesize codePaper;
@synthesize audioPaper;
@synthesize photosPaper;
@synthesize graphicsPaper;
@synthesize backButton;
@synthesize reviewButton;

- (void) didLoadFromCCB {
    // set up the version and build
    [self.version setString:[NSString stringWithFormat:@"%@.%@",
                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    CGPoint codePaperFinalPos = self.codePaper.position;
    self.codePaper.position = ccp( -400, 300 );
    self.codePaper.rotation = 20;
    self.codePaper.scale = 2.0f;

    CGPoint graphicsPaperFinalPos = self.graphicsPaper.position;
    self.graphicsPaper.position = ccp( 300, -300 );
    self.graphicsPaper.rotation = -30;
    self.graphicsPaper.scale = 2.0f;

    CGPoint photosPaperFinalPos = self.photosPaper.position;
    self.photosPaper.position = ccp( 1400, 800 );
    self.photosPaper.rotation = -20;
    self.photosPaper.scale = 2.0f;

    CGPoint audioPaperFinalPos = self.audioPaper.position;
    self.audioPaper.position = ccp( 1400, 200 );
    self.audioPaper.rotation = 20;
    self.audioPaper.scale = 2.0f;

    // animate in them all
    [self moveNode:self.codePaper toPos:codePaperFinalPos inTime:0.6f atRate:1.5f];
    [self scaleNode:self.codePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.codePaper toAngle:-6 inTime:0.5f atRate:2.0f];

    [self moveNode:self.graphicsPaper toPos:graphicsPaperFinalPos inTime:0.6f atRate:1.2f];
    [self scaleNode:self.graphicsPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.graphicsPaper toAngle:9 inTime:0.5f atRate:2.0f];

    [self moveNode:self.photosPaper toPos:photosPaperFinalPos inTime:0.6f atRate:1.6f];
    [self scaleNode:self.photosPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.photosPaper toAngle:8 inTime:0.5f atRate:3.0f];

    [self moveNode:self.audioPaper toPos:audioPaperFinalPos inTime:0.6f atRate:1.8f];
    [self scaleNode:self.audioPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.audioPaper toAngle:-6 inTime:0.5f atRate:2.5f];

    // these can be animated
    [self addAnimatableNode:self.codePaper];
    [self addAnimatableNode:self.graphicsPaper];
    [self addAnimatableNode:self.photosPaper];
    [self addAnimatableNode:self.audioPaper];

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Review" forButton:self.reviewButton];

    [self.versionName setString:sVersionString];
    self.versionName.visible = YES;

    // fade in the buttons
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
    [self fadeNode:self.reviewButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];

    [Answers logCustomEventWithName:@"About shown"
                   customAttributes:nil];
}


- (void) review {
    [Answers logCustomEventWithName:@"Review launched"
                   customAttributes:nil];

    NSURL * url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id688783079"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];
    [self disableBackButton:self.reviewButton];

    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) animationsDone {
    [[CCDirector sharedDirector] popScene];
}


+ (id) node {
	return [CCBReader sceneWithNodeGraphFromFile:@"About.ccb"];
}

@end
