
#import "cocos2d.h"

@class Scenario;

@interface ScenarioInfoNode : CCNode

@property (nonatomic, weak)   Scenario *         scenario;
@property (nonatomic, strong) CCLabelBMFont *    scenarioTitle;
@property (nonatomic, strong) CCLabelBMFont *    description;
@property (nonatomic, strong) CCMenuItemImage *  playButton;
@property (nonatomic, strong) CCMenuItemImage *  replayButton;

+ (ScenarioInfoNode *) nodeWithScenario:(Scenario *)scenario;

- (void) remove;

@end
