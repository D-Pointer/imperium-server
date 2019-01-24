
#import "ShouldHold.h"
#import "Organization.h"

@implementation ShouldHold

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.organization.order == kHold ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
