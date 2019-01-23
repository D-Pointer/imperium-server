
#import "IsFormationMode.h"

@implementation IsFormationMode

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.mode == kFormation ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
