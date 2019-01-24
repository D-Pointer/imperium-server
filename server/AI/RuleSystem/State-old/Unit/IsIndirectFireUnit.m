
#import "IsIndirectFireUnit.h"
#import "Scenario.h"

@implementation IsIndirectFireUnit

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.weapon.type == kMortar || context.unit.weapon.type == kHowitzer ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
