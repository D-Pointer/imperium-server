
#import "IsCavalryUnit.h"

@implementation IsCavalryUnit

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.type == kCavalry || context.unit.type == kCavalryHeadquarter ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
