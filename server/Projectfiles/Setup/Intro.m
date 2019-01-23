
// DEBUG: enable for testing crashes
//#import <Fabric/Fabric.h>
//#import <Crashlytics/Crashlytics.h>

#import "CCBReader.h"

#import "Intro.h"
#import "Globals.h"
#import "MainMenu.h"
#import "ResourceDownloader.h"
#import "ScenarioIndexParser.h"
#import "ParameterHandler.h"

// includes for hardcoded start
#import "Scenario.h"
#import "MapReader.h"
#import "GameLayer.h"
#import "LineOfSight.h"
#import "StateMachineAI.h"
#import "ScenarioScript.h"

@interface Intro () {
    int currentLine;
}

@property (nonatomic, strong) NSArray * storyLines;
@property (nonatomic, strong) ResourceDownloader * resourceDownloader;
@property (nonatomic, assign) BOOL downloadCompleted;

@end


@implementation Intro

@synthesize logo;
@synthesize storyPaper;
@synthesize text;
@synthesize continueLabel;

+ (CCScene *) scene {
    return [CCBReader sceneWithNodeGraphFromFile:@"Intro.ccb"];
}


- (void) didLoadFromCCB {
    // load the store into an array of strings, one string per line
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *storyPath = [bundlePath stringByAppendingPathComponent:@"Story.txt"];
    NSString *storyText = [NSString stringWithContentsOfFile:storyPath encoding:NSUTF8StringEncoding error:nil];
    self.storyLines = [storyText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    currentLine = -1;

    // the paper is animated out
    [self addAnimatableNode:self.storyPaper];

    // start playing music
    [[Globals sharedInstance].audio playMusic:kMenuMusic];

    self.downloadCompleted = NO;
    self.resourceDownloader = [[ResourceDownloader alloc] initWithDelegate:self];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    CGPoint finalLogoPos = self.logo.position;
    self.logo.position = ccp( 500, 500 );
    self.logo.scale = 10.0f;

    // animate in the logo after a short delay. The delay is because of the hack in AppDelegate.m that fixes the short
    // fading to black between the launch storyboard and the intro scene. Start animating the logo a bit later so that
    // the animation is visible.
    [self.logo runAction:[CCSequence actions:
                          [CCDelayTime actionWithDuration:0.3f],
                          [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.4f position:finalLogoPos]
                                                rate:1.5f],
                          nil]];

    [self.logo runAction:[CCSequence actions:
                          [CCDelayTime actionWithDuration:0.3f],
                          [CCScaleTo actionWithDuration:0.5f scale:1.0f],
                          nil]];

    // we handle touches, make sure we get before all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority + 1 swallowsTouches:YES];

    // do a first update immediately
    [self addText];

    // start downloading data
    [self.resourceDownloader downloadResources];

    self.continueLabel.visible = YES;
    self.continueLabel.opacity = 255;
    [self.continueLabel setString:[NSString stringWithFormat:@"Downloading data"]];
}


- (void) onExit {
    [super onExit];
    CCLOG( @"in" );

    // no mre touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if ( self.downloadCompleted ) {
        [self done];
    }

    return YES;
}


- (void) addText {
    currentLine++;

    // last line?
    if ( currentLine >= (int)self.storyLines.count ) {
        // yes, we're done, can we proceed?
        if ( self.downloadCompleted ) {
            [self done];
            return;
        }

        // we can't yet proceed, likely still downloading data
        currentLine = 0;
    }

    // for the description we need to add word by word
    NSArray * words = [self.storyLines[currentLine] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString * line = @"";
    NSMutableArray * lines = [NSMutableArray new];

    // add words to the line until the length overflows
    for ( NSString * word in words ) {
        NSString * tmp = [line stringByAppendingString:word];
        [self.text setString:tmp];

        // too long?
        if ( self.text.boundingBox.size.width > 250 ) {
            // start a new line
            [lines addObject:line];
            line = [word stringByAppendingString:@" "];
        }
        else {
            // not too long yet
            line = [tmp stringByAppendingString:@" "];
        }
    }

    // add in the last half line too
    [lines addObject:line];

    // join the lines and use as the label
    [self.text setString:[lines componentsJoinedByString:@"\n"]];

    // various positions
    CGPoint startPos = ccp( -300, 200 + CCRANDOM_0_1() * 100 );
    CGPoint mapPos = ccp( 225 - 15 + CCRANDOM_0_1() * 15, 150 + CCRANDOM_0_1() * 30 );
    CGPoint endPos = ccp( 512 - 200 + CCRANDOM_0_1() * 400, -200 );

    // all angles
    float startAngle = -150 + CCRANDOM_0_1() * 300;
    float mapAngle   = -15 + CCRANDOM_0_1() * 30;
    float endAngle   = -100 + CCRANDOM_0_1() * 200;

    // first position outside and scale it up
    self.storyPaper.position = startPos;
    self.storyPaper.rotation = startAngle;
    self.storyPaper.scale = 2.0f;

    [self.storyPaper runAction:[CCSequence actions:
                                // animate in
                                [CCSpawn actions:
                                 [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.8 position:mapPos] rate:1.0],
                                 [CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:0.7 scale:1.0f] rate:1.0],
                                 [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.8 angle:mapAngle] rate:1.0], nil],

                                // wait some time with the text on the map
                                [CCDelayTime actionWithDuration:5],

                                // animate out
                                [CCSpawn actions:
                                 [CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.6 position:endPos] rate:1.5],
                                 [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.6 angle:endAngle] rate:2.0], nil],

                                // next image
                                [CCCallFunc actionWithTarget:self selector:@selector(addText)],
                                nil]];

}


- (void) done {
    // parse the scenario index file
    [[ScenarioIndexParser new] parseScenarioIndexFile];

    // read all parameters
    [[Globals sharedInstance].parameterHandler readParameters];


    for ( int index = 0; index < kParameterCount; ++index ) {
        CCLOG( @"parameter value %d float: %.1f int: %d", index, sParameters[index].floatValue, sParameters[index].intValue );
    }

    [self.storyPaper stopAllActions];

    // DEBUG: test crashlytics
    //[[Crashlytics sharedInstance] crash];
    
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    if ( sLoadHardcodedScenario ) {
        [self hardcodedLoading];
    }
    else {
        [self animateNodesAwayAndShowScene:[MainMenu node]];
    }
}


- (void) hardcodedLoading {
    Globals *globals = [Globals sharedInstance];

    [globals reset];

    // single player game
    globals.gameType = kSinglePlayerGame;
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kAIPlayer];

    globals.campaignId = 0;
    Scenario * scenario = nil;

    for ( Scenario * tmp in globals.scenarios ) {
        if ( tmp.scenarioId == 14 ) {
            scenario = tmp;
        }
    }

    NSAssert( scenario, @"scenario not found!" );
    globals.scenario = scenario;

    // create the real game scene
    [[CCDirector sharedDirector] replaceScene:[GameLayer node]];

    // load the map
    [[MapReader new] completeScenario:globals.scenario];

    // set the objective owners
    [Objective updateOwnerForAllObjectives];

    // initial line of sight update for the current player
    globals.lineOfSight = [LineOfSight new];
    [globals.lineOfSight update];

    // center the map on the first unit. The first tutorial however has no units
    if ( globals.unitsPlayer1.count > 0 ) {
        [globals.gameLayer centerMapOn:[globals.unitsPlayer1 objectAtIndex:0]];
    }

    // set up the AI
    globals.ai = [StateMachineAI new];

    // setup the scenario script
    [globals.scenarioScript setupForScenario:globals.scenario];
}


//***************************************************************************************************************
#pragma mark - Online games delegate

- (void) resourcesDownloaded {
    dispatch_async(dispatch_get_main_queue(), ^{
        CCLOG( @"resources downloaded ok" );
        [self.continueLabel setString:@"Tap to continue"];
        self.downloadCompleted = YES;
    } );
}


- (void) resourcesFailedWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        CCLOG( @"failed to download resources: %@", error != nil ? error.localizedDescription : @"no error" );
        [self.continueLabel setString:@"Failed to download resources!"];
    } );
}


@end
