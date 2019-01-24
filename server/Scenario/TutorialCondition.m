
#import "TutorialCondition.h"

@implementation TutorialCondition

- (ScenarioState) check {
    // tutorials never end
    return kGameInProgress;
}

@end
