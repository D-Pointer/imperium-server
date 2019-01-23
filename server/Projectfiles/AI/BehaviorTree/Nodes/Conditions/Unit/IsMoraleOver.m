
#import "IsMoraleOver.h"

@implementation IsMoraleOver

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    // morale must be over the limit
    if ( context.unit.morale > (float)self.value ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
