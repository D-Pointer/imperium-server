
#import "IsIdle.h"

@implementation IsIdle

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.mission.type == kIdleMission ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
