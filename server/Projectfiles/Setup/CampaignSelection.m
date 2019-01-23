
#import <Crashlytics/Answers.h>

#import "CCBReader.h"

#import "CampaignSelection.h"
#import "MainMenu.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "ResumeGame.h"
#import "SelectScenario.h"
#import "MainMenu.h"

@interface CampaignSelection ()

@property (nonatomic, strong) CCScene * sceneToPush;

@end



@implementation CampaignSelection

@synthesize logo;
@synthesize paper;
@synthesize menuPaper;
@synthesize button0;
@synthesize button1;
@synthesize button2;
@synthesize button3;
@synthesize backButton;

- (void) didLoadFromCCB {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    // get the campaign started flags
    BOOL started0 = [defaults boolForKey:@"campaignStarted0"];
    BOOL started1 = [defaults boolForKey:@"campaignStarted1"];
    BOOL started2 = [defaults boolForKey:@"campaignStarted2"];
    BOOL started3 = [defaults boolForKey:@"campaignStarted3"];

    // create texts
    if ( started0 ) {
        [self createText:@"Campaign 1" forButton:self.button0];
    }
    else {
        [self createText:@"New Campaign" forButton:self.button0 withFont:@"ButtonFont2.fnt"];
    }

    if ( started1 ) {
        [self createText:@"Campaign 2" forButton:self.button1];
    }
    else {
        [self createText:@"New Campaign" forButton:self.button1 withFont:@"ButtonFont2.fnt"];
    }

    if ( started2 ) {
        [self createText:@"Campaign 3" forButton:self.button2];
    }
    else {
        [self createText:@"New Campaign" forButton:self.button2 withFont:@"ButtonFont2.fnt"];
    }

    if ( started3 ) {
        [self createText:@"Campaign 4" forButton:self.button3];
    }
    else {
        [self createText:@"New Campaign" forButton:self.button3 withFont:@"ButtonFont2.fnt"];
    }

    [self createText:@"Back" forButton:self.backButton];

    // no scene to push yet
    self.sceneToPush = nil;
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    CGPoint paperFinalPos = self.paper.position;
    CGPoint menuPaperFinalPos = self.menuPaper.position;

    self.paper.position = ccp( -300, 300 );
    self.paper.rotation = 20;
    self.paper.scale = 2.0f;

    self.menuPaper.position = ccp( 1500, 200 );
    self.menuPaper.rotation = -20;
    self.menuPaper.scale = 2.0f;

    // animate in them all
    [self moveNode:self.paper toPos:paperFinalPos inTime:0.5f atRate:1.5f];
    [self scaleNode:self.paper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.paper toAngle:-6 inTime:0.5f atRate:2.0f];

    [self moveNode:self.menuPaper toPos:menuPaperFinalPos inTime:0.5f atRate:1.5f];
    [self scaleNode:self.menuPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.menuPaper toAngle:2 inTime:0.5f atRate:2.0f];

    // these can be animated
    [self addAnimatableNode:self.paper];
    [self addAnimatableNode:self.menuPaper];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    // we should pop our scene, thus nil
    self.sceneToPush = nil;

    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) selectCampaign:(id)sender {
    // save the id of the campaign
    [Globals sharedInstance].campaignId = (int)((CCMenuItemImage *)sender).tag;

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    // set the campaign started flags
    [defaults setBool:YES forKey:[NSString stringWithFormat:@"campaignStarted%d", [Globals sharedInstance].campaignId]];
    [defaults synchronize];

    CCLOG( @"using campaign: %d", [Globals sharedInstance].campaignId );

    // analytics
    [Answers logCustomEventWithName:@"Campaign selection"
                   customAttributes:@{ @"campaignId" : @([Globals sharedInstance].campaignId) } ];

    // do we have a resumeable game?
    if ( [GameSerializer hasSavedGame:[NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId] ] ) {
        // make sure the player knows what he/she is doing and ask
        self.sceneToPush = [ResumeGame node];
    }
    else {
        self.sceneToPush = [SelectScenario node];
    }

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];

    // animate out the logo
    [self moveNode:self.logo toPos:ccpAdd( self.logo.position, ccp(0, 500)) inTime:1.0f atRate:1.5f];
    [self fadeNode:self.logo toAlpha:0 inTime:1.0f atRate:1.0f];

    // disable back button
    [self disableBackButton:self.backButton];
}


- (void) animationsDone {
    // any scene to push or create the main menu?
    if ( self.sceneToPush == nil ) {
        [[CCDirector sharedDirector] replaceScene:[MainMenu node]];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:self.sceneToPush];
    }
}


+ (id) node {
	return [CCBReader sceneWithNodeGraphFromFile:@"CampaignSelection.ccb"];
}

@end
