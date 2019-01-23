
#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "HostGame.h"
#import "Globals.h"
#import "GameSerializer.h"
#import "Lobby.h"
#import "Wait.h"
#import "Utils.h"

@interface HostGame ()

@property (nonatomic, weak)   Scenario * scenario;

@end


@implementation HostGame

@synthesize hostButton;
@synthesize backButton;
@synthesize scenarioInfoPaper;
@synthesize helpPaper;
@synthesize scenarioTitle;
@synthesize scenarioDescription;


+ (id) nodeWithScenario:(Scenario *)scenario {
    HostGame * node = (HostGame *)[CCBReader nodeGraphFromFile:@"HostGame.ccb"];
    node.scenario = scenario;

    // create the texts
    [node.scenarioTitle setString:scenario.title];

    // and the description
    [Utils showString:scenario.information onLabel:node.scenarioDescription withMaxLength:350];

    // embed in a scene
    CCScene * scene = [CCScene new];
    [scene addChild:node];
    return scene;
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Host" forButton:self.hostButton];
    [self createText:@"Back" forButton:self.backButton];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.scenarioInfoPaper.position = ccp( 600, -200 );
    self.scenarioInfoPaper.rotation = -50;
    self.scenarioInfoPaper.scale = 2.0f;
    self.helpPaper.position = ccp( 300, 900 );
    self.helpPaper.rotation = 50;
    self.helpPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.scenarioInfoPaper toPos:ccp(350, 350) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.scenarioInfoPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.scenarioInfoPaper toAngle:-3 inTime:0.5f atRate:0.5f];
    [self moveNode:self.helpPaper toPos:ccp(780, 390) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.helpPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.helpPaper toAngle:5 inTime:0.5f atRate:0.5f];

    // these can be animated
    [self addAnimatableNode:self.scenarioInfoPaper];
    [self addAnimatableNode:self.helpPaper];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) hostGame {
    CCLOG( @"in" );
    Globals * globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    // try to announce the scenario
    CCLOG( @"announcing scenario: %@", self.scenario );
    [[Globals sharedInstance].tcpConnection announceScenario:self.scenario];

    // this is now our current scenario
    globals.scenario = self.scenario;

    [Answers logCustomEventWithName:@"Host online scenario"
                   customAttributes:@{ @"title" : self.scenario.title }];

    // now show the scene where we wait for the opponent to connect
    [self animateNodesAwayAndShowScene:[Wait node]];

    // disable and fade out back button
    [self disableBackButton:self.backButton];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    [self animateNodesAwayAndShowScene:[Lobby node]];
}



@end
