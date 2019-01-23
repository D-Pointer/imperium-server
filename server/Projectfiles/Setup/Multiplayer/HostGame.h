
#import "Layer.h"
#import "Scenario.h"

@interface HostGame : Layer

@property (nonatomic, strong) CCMenuItemImage * hostButton;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          scenarioInfoPaper;
@property (nonatomic, strong) CCNode *          helpPaper;
@property (nonatomic, strong) CCLabelBMFont *   scenarioTitle;
@property (nonatomic, strong) CCLabelBMFont *   scenarioDescription;

+ (id) nodeWithScenario:(Scenario *)scenario;

@end
