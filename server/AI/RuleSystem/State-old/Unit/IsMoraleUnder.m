
#import "IsMoraleUnder.h"

@implementation IsMoraleUnder

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    // morale must be over the limit
    if ( context.unit.morale < (float)self.value ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
