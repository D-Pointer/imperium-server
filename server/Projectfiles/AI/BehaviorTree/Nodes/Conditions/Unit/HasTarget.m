#import "HasTarget.h"
#import "CombatMission.h"

@implementation HasTarget

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if (context.unit.mission && [context.unit.mission isKindOfClass:[CombatMission class]]) {
        return kSucceeded;
    }

    return kFailed;
}

@end
