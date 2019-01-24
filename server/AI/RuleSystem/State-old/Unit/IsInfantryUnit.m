
#import "IsInfantryUnit.h"

@implementation IsInfantryUnit

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.type == kInfantry || context.unit.type == kInfantryHeadquarter ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
