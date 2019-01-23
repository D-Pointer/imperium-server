
#import "IsHq.h"
#import "Scenario.h"

@implementation IsHq

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.type == kInfantryHeadquarter || context.unit.type == kCavalryHeadquarter ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
