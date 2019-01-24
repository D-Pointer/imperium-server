
#import "IsSupportUnit.h"
#import "Scenario.h"

@implementation IsSupportUnit

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    return context.unit.isSupport ? kSucceeded : kFailed;
}

@end
