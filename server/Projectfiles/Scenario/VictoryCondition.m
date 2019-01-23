
#import "VictoryCondition.h"

@implementation VictoryCondition


- (void) setup {
    // nothing to do
}


- (ScenarioState) check {
    // by default never ends
    return kGameInProgress;
}

@end
