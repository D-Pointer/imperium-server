
#import "ShouldTakeObjective.h"
#import "Organization.h"

@implementation ShouldTakeObjective

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.organization.order == kTakeObjective ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
