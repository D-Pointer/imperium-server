
#import "IsColumnMode.h"
#import "Scenario.h"

@implementation IsColumnMode

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.mode == kColumn ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
