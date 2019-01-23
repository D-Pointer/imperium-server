
#import "IsFatigueOver.h"

@implementation IsFatigueOver

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    // fatigue must be less than the limit
    if ( context.unit.fatigue < (float)self.value ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
