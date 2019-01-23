
#import "CCBReader.h"

#import "Scenario.h"
#import "ScenarioInfoNode.h"
#import "GameLayer.h"
#import "Globals.h"
#import "Utils.h"

@implementation ScenarioInfoNode

// these are needed for CocosBuilder's stuff to work!
@synthesize scenarioTitle;
@synthesize description;
@synthesize playButton;
@synthesize replayButton;

+ (ScenarioInfoNode *) nodeWithScenario:(Scenario *)scenario {
    ScenarioInfoNode * node = (ScenarioInfoNode *)[CCBReader nodeGraphFromFile:@"ScenarioInfoNode.ccb"];

    // save the scenario info too
    node.scenario = scenario;

    // create the texts
    [node.scenarioTitle setString:node.scenario.title];

    // and the description
    [Utils showString:scenario.information onLabel:node.description withMaxLength:350];

    // set up the buttons
    [Utils createText:@"Play"   forButton:node.playButton];
    [Utils createText:@"Replay" forButton:node.replayButton];
//
//    // split the length into hours an minutes
//    int hours = scenario.length / 3600;
//    int minutes = (scenario.length % 3600) / 60;
//
//    // create a nice string
//    NSString * length;
//    if ( hours == 0 ) {
//        length = [NSString stringWithFormat:@"%d minutes", minutes];
//    }
//    else if ( minutes == 0 ) {
//        if ( hours == 1 ) {
//            length = [NSString stringWithFormat:@"%d hour", hours];
//        }
//        else {
//            length = [NSString stringWithFormat:@"%d hours", hours];
//        }
//    }
//    else {
//        if ( hours == 1 ) {
//            length = [NSString stringWithFormat:@"%d:%02d hour", hours, minutes];
//        }
//        else {
//            length = [NSString stringWithFormat:@"%d:%02d hours", hours, minutes];
//        }
//    }
//
//    [node.scenarioLength setString:length];

    int campaignId = [Globals sharedInstance].campaignId;

    // which buttons do we show?
    if ( node.scenario.scenarioType == kTutorial ) {
        if ([node.scenario isCompletedForCampaign:campaignId]) {
            node.replayButton.visible   = YES;
            node.replayButton.isEnabled = YES;
            node.playButton.visible = NO;
        }
        else {
            node.playButton.visible   = YES;
            node.playButton.isEnabled = YES;
            node.replayButton.visible = NO;
        }
    }

    else if ( [Globals sharedInstance].gameType == kSinglePlayerGame ) {
        if ( [node.scenario isCompletedForCampaign:campaignId] ) {
            node.playButton.visible     = NO;
            node.replayButton.visible   = YES;
            node.replayButton.isEnabled = YES;
        }
        else {
            node.playButton.visible   = YES;
            node.playButton.isEnabled = YES;
            node.replayButton.visible = NO;
        }
    }

    // online or multiplayer
    else {
        node.playButton.visible   = YES;
        node.playButton.isEnabled = YES;
        node.replayButton.visible = NO;
    }

    return node;
}


- (void) remove {
    [self removeFromParentAndCleanup:YES];
}


- (void) play {
    // disable the button to avoid having many presses
    self.playButton.isEnabled = NO;

    // let the world know
    [[NSNotificationCenter defaultCenter] postNotificationName:sNotificationScenarioSelected object:nil ];
}


@end
