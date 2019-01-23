
#import "cocos2d.h"
#import "Layer.h"
#import "ScenarioMap.h"

@interface SelectScenario : Layer <ScenarioMapDelegate, PanZoomNodeDelegate>

@property (nonatomic, strong) ScenarioMap *     scenarioMap;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * editorButton;
@property (nonatomic, strong) CCMenuItemImage * resetButton;
@property (nonatomic, strong) CCNode *          paper;
@property (nonatomic, strong) CCLabelBMFont *   paperText;
@property (nonatomic, strong) CCLabelBMFont *   loadingNode;

@end
