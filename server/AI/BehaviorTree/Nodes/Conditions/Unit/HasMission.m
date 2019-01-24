
#import "HasMission.h"
#import "IdleMission.h"

@implementation HasMission

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    Unit * unit = context.unit;
    if ( unit.mission && unit.mission.type != kIdleMission ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
