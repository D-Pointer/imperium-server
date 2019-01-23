#import "CCBReader.h"

#import "ScenarioMap.h"
#import "Globals.h"
#import "Utils.h"

@interface ScenarioMap ()

@property (nonatomic, readwrite, assign) int completedScenarios;
@property (nonatomic, readwrite, assign) int playableScenarios;

@end

@implementation ScenarioMap

@synthesize background;
@synthesize menu;
@synthesize citiesNode;

+ (CCNode *) node {
    // the node we wrap
    ScenarioMap *node = (ScenarioMap *) [CCBReader nodeGraphFromFile:@"ScenarioMap.ccb"];
    [node setContentSize:node.background.contentSize];
    [node createContent];

    return node;
}


- (void) createContent {
    NSMutableArray *playableScenarioButtons = [NSMutableArray new];

    Globals *globals = [Globals sharedInstance];

    // how many tutorials are completed?
    self.completedScenarios = 0;
    int campaignId = [Globals sharedInstance].campaignId;

    // update the positions of all cities. They must be moved out as they were placed according to a background
    // that was scaled down to fit
    for (CCNode *node in self.citiesNode.children) {
        node.position = ccpMult( node.position, 1.445f );
    }
    for (CCNode *node in self.menu.children) {
        node.position = ccpMult( node.position, 1.445f );
    }

    for (Scenario *scenario in globals.scenarios) {
        // find the scenario if it is present at all in this CCB file and hide it
        CCMenuItemSprite *button = (CCMenuItemSprite *) [self.menu getChildByTag:scenario.scenarioId];
        if (!button) {
            CCLOG( @"************ missing scenario, no button found for %d (%@) ************", scenario.scenarioId, scenario.title );
            continue;
        }

        // is it completed?
        if ([scenario isCompletedForCampaign:campaignId]) {
            self.completedScenarios++;
        }

        // is it playable at this point?
        if (!sDebugAllScenarios) {
            if (![scenario isPlayableForCampaign:campaignId]) {
                // DEBUG: comment the next two lines out to enable all scenarios
                button.visible = NO;
                continue;
            }
        }

        // for multiplayer and online we skip the tutorials
        if (scenario.scenarioType == kTutorial && globals.gameType != kSinglePlayerGame) {
            button.visible = NO;
            continue;
        }

        // completed scenarios have a different icon
        if (globals.gameType == kSinglePlayerGame && [scenario isCompletedForCampaign:campaignId]) {
            button.normalImage = [CCSprite spriteWithSpriteFrameName:@"BattleCompleted.png"];
            button.selectedImage = [CCSprite spriteWithSpriteFrameName:@"BattleCompletedPressed.png"];
        }
        else {
            // it's playable but not completed and should be animated later
            [playableScenarioButtons addObject:button];
        }

        CCLOG( @"playable: %@", scenario.title );

        // add in a text with the scenario name
        CCLabelBMFont *title = [CCLabelBMFont labelWithString:@"" fntFile:@"ScenarioNameFont.fnt"];
        title.position = ccpAdd( button.position, ccp( 0, -30 ) );
        title.anchorPoint = ccp( 0.5f, 0.5f );
        title.alignment = kCCTextAlignmentCenter;
        [self addChild:title];

        // create the title
        [Utils showString:scenario.title onLabel:title withMaxLength:125];
    }

    self.playableScenarios = (int)playableScenarioButtons.count;
    CCLOG( @"completed: %d, playable: %d", self.completedScenarios, self.playableScenarios );

    // finally animate all the buttons that represent playable scenarios
    for (CCMenuItemSprite *button in playableScenarioButtons) {
        [button runAction:
                [CCSequence actions:
                        [CCScaleTo actionWithDuration:0.4f scale:1.1f],
                        [CCScaleTo actionWithDuration:0.4f scale:0.9f],
                        [CCScaleTo actionWithDuration:0.4f scale:1.1f],
                        [CCScaleTo actionWithDuration:0.4f scale:0.9f],
                        [CCScaleTo actionWithDuration:0.4f scale:1.1f],
                        [CCScaleTo actionWithDuration:0.4f scale:0.9f],
                        [CCScaleTo actionWithDuration:0.4f scale:1.0f],
                                nil]];
    }
}


- (void) battlePressed:(id)sender {
    CCMenuItemSprite *battle = (CCMenuItemSprite *) sender;

    Scenario *pressed = nil;

    // find the scenario with the same id as the tag. it's not an index!
    for (Scenario *tmp in [Globals sharedInstance].scenarios) {
        if (tmp.scenarioId == battle.tag) {
            pressed = tmp;
        }
    }

    if (pressed == nil) {
        CCLOG( @"no scenario found for id tag: %ld", (long) battle.tag );
        NSAssert( pressed, @"no scenario found for id tag in button" );
    }

    CCLOG( @"pressed scenario: %@", pressed );
    CCLOG( @"delegate: %@", self.delegate );

    if (self.delegate) {
        [self.delegate scenarioPressed:pressed];
    }
}

@end
