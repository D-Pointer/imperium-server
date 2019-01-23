
#import "ShouldAdvance.h"
#import "Organization.h"

@implementation ShouldAdvance

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.organization.order == kAdvanceTowardsEnemy ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
