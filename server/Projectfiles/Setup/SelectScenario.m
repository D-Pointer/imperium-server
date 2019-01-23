#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "SelectScenario.h"
#import "GameLayer.h"
#import "Globals.h"
#import "ScenarioInfoNode.h"
#import "MapReader.h"
#import "LineOfSight.h"
#import "LoadEditor.h"
#import "CampaignSelection.h"
#import "Utils.h"
#import "ScenarioMap.h"
#import "ScenarioScript.h"
#import "StateMachineAI.h"
#import "ResetCampaign.h"

@interface SelectScenario ()

@property (nonatomic, strong) ScenarioInfoNode *shownNode;

@end


@implementation SelectScenario

@synthesize shownNode;
@synthesize backButton;
@synthesize editorButton;
@synthesize resetButton;
@synthesize paper;
@synthesize paperText;
@synthesize loadingNode;

+ (CCScene *) node {
    SelectScenario *node = (SelectScenario *) [CCBReader nodeGraphFromFile:@"SelectScenario.ccb"];

    [node createContent];

    // wrap in a scene
    CCScene *scene = [CCScene node];
    [scene addChild:node];
    return scene;
}


- (void) createContent {
    // create the background pannable node
    self.scenarioMap = [ScenarioMap node];
    self.scenarioMap.delegate = self;

    // create the pan/zoom node
    CGSize size = CGSizeMake( 1024, 768 );
    PanZoomNode *panZoomNode = [[PanZoomNode alloc] initWithSize:size];
    panZoomNode.delegate = self;
    panZoomNode.node = self.scenarioMap;
    panZoomNode.maxScale = 1.0f;
    panZoomNode.minScale = MAX( size.width / self.scenarioMap.contentSize.width, size.height / self.scenarioMap.contentSize.height );
    [self addChild:panZoomNode];

    self.shownNode = nil;

    // we handle touches
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];

    CCLOG( @"completed: %d, playable: %d", self.scenarioMap.completedScenarios, self.scenarioMap.playableScenarios );

    // show the little help paper if the player is just starting a career
    if ( self.scenarioMap.completedScenarios < 4) {
        // what text?
        if (self.scenarioMap.completedScenarios == 0) {
            [Utils showString:@"Start your commander training with a few tutorial battles to get to know the basics." onLabel:self.paperText withMaxLength:250];
        }
        else if (self.scenarioMap.completedScenarios == 1) {
            [Utils showString:@"You still need some more training before you can command your own troops in real battles." onLabel:self.paperText withMaxLength:250];
        }
        else if (self.scenarioMap.completedScenarios == 2) {
            [Utils showString:@"The third and final training mission introduces combat." onLabel:self.paperText withMaxLength:250];
        }
        else if (self.scenarioMap.completedScenarios == 3) {
            [Utils showString:@"Your training is now complete and you will get to lead your troops in real battles!" onLabel:self.paperText withMaxLength:250];
        }

        // position all nodes outside
        self.paper.position = ccp( 300, -300 );
        self.paper.rotation = -50;
        self.paper.scale = 2.0f;

        [self moveNode:self.paper toPos:ccp( 800, 470 ) inTime:0.5f atRate:1.8f];
        [self scaleNode:self.paper toScale:1.0f inTime:0.4f];
        [self rotateNode:self.paper toAngle:8 inTime:0.4f atRate:2.5f];

        self.loadingNode.position = ccp( 500, 1200 );
        self.loadingNode.rotation = 50;
        self.loadingNode.scale = 2.0f;

        // the paper can be animated
        [self addAnimatableNode:self.paper];
        self.paper.visible = YES;
    }
    else {
        self.paper.visible = NO;
    }

    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Editor" forButton:self.editorButton];
    [self createText:@"Reset" forButton:self.resetButton];

    // fade in the Back and Editor button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0.5 inTime:1];
    [self fadeNode:self.editorButton fromAlpha:0 toAlpha:255 afterDelay:0.5 inTime:1];
    [self fadeNode:self.resetButton fromAlpha:0 toAlpha:255 afterDelay:0.5 inTime:1];

    // DEBUG: should we show the editor button?
    self.editorButton.visible = sEnableEditor;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) back {
    CCLOG( @"in" );
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];
    [self disableBackButton:self.editorButton];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    [self animateNodesAwayAndShowScene:[CampaignSelection node]];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );

    if (self.shownNode) {
        // stop all actions and animate away
        [self.shownNode stopAllActions];
        [self animateAway];
        self.shownNode = nil;

        [[Globals sharedInstance].audio playSound:kScenarioDeselected];
    }

    return NO;
}


- (void) scenarioPressed:(Scenario *)scenario {
    CCLOG( @"scenario pressed: %@", scenario );

    [[Globals sharedInstance].audio playSound:kScenarioSelected];

    // tapped the same battle?
    if (self.shownNode != nil && self.shownNode.scenario == scenario) {
        // simply hide the old infoNode
        [self animateAway];
        self.shownNode = nil;
        return;
    }

    // create the info node
    ScenarioInfoNode *infoNode = [ScenarioInfoNode nodeWithScenario:scenario];
    infoNode.position = ccp( -300, 300 );
    infoNode.rotation = 10;
    infoNode.scale = 1.5f;
    [self addChild:infoNode z:20];

    // we want to know when the phase changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( scenarioSelected: ) name:sNotificationScenarioSelected object:nil];

    // animate away any old info node
    if (self.shownNode) {
        [self animateAway];
    }

    self.shownNode = infoNode;

    // this can also be animated away when the scene is done
    [self addAnimatableNode:self.shownNode];

    // animate in the new infoNode
    [self moveNode:self.shownNode toPos:ccp( 230, 400 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.shownNode toScale:1.0f inTime:0.5f];
    [infoNode runAction:[CCSequence actions:
            [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.5f angle:-10]
                                  rate:2],
            [CCCallFunc actionWithTarget:self selector:@selector( animationInDone )],
                    nil]];
}


- (void) animateAway {
    self.shownNode.playButton.isEnabled = NO;
    self.shownNode.replayButton.isEnabled = NO;

    // the shown node can no longer be animated away
    [self removeAnimatableNode:self.shownNode];

    [self rotateNode:self.shownNode toAngle:10 inTime:0.5f atRate:2];
    [self.shownNode runAction:[CCSequence actions:
            [CCEaseOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:ccp( 200, 900 )]
                                   rate:1.0f],
            [CCCallFunc actionWithTarget:self.shownNode selector:@selector( remove )],
                    nil]];
}


- (void) animationInDone {
    self.shownNode.playButton.isEnabled = YES;
}


- (void) scenarioSelected:(NSNotification *)notification {
    // no more callbacks to us. if this is not done then we will crash when the second game is started and the
    // "scenarioSelected" notification is sent
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // hide the back button
    self.backButton.visible = NO;

    Globals *globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    // this is now our current scenario
    Scenario *scenario = self.shownNode.scenario;
    globals.scenario = scenario;

    CCLOG( @"selected scenario: %@", scenario );

    // the players must be set before the game layer is set up and the scenario parsed
    globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
    globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kAIPlayer];
    globals.localPlayer = globals.player1;

    [Answers logCustomEventWithName:@"Start single player scenario"
                   customAttributes:@{@"title" : scenario.title}];

    // animate out stuff
    [self animateNodesAwayWithSelector:@selector( animationsOutDone )];

    // animate in the loading node
    [self moveNode:self.loadingNode toPos:ccp( 512, 368 ) inTime:0.5f atRate:1.8f];
    [self scaleNode:self.loadingNode toScale:1.0f inTime:0.4f];
    [self rotateNode:self.loadingNode toAngle:-4 inTime:0.4f atRate:2.5f];

    self.loadingNode.visible = YES;
}


- (void) animationsOutDone {
    CCLOG( @"in" );
    Globals *globals = [Globals sharedInstance];

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


- (void) loadFromEditor {
    CCLOG( @"in" );

    // disable buttons
    [self disableBackButton:self.backButton];
    [self disableBackButton:self.editorButton];
    [self disableBackButton:self.resetButton];

    // create the real game scene
    [[CCDirector sharedDirector] replaceScene:[LoadEditor node]];
}


- (void) resetCampaign {
    CCLOG( @"in" );

    // disable buttons
    [self disableBackButton:self.backButton];
    [self disableBackButton:self.editorButton];
    [self disableBackButton:self.resetButton];

    // create the real game scene
    [[CCDirector sharedDirector] replaceScene:[ResetCampaign node]];
}


- (void) node:(CCNode *)node tappedAt:(CGPoint)pos {
    CCLOG( @"tapped" );

    // animate away any old info node
    if (self.shownNode) {
        [self animateAway];
    }
}

@end
