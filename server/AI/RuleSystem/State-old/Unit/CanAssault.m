
#import "CanAssault.h"
#import "Scenario.h"

@implementation CanAssault

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    Unit * unit = context.unit;

    // check the basic stuff first
    if ( unit.assaultSpeed <= 0 || unit.mode == kColumn || ! [unit isIdle] || ! [unit canBeGivenMissions] ) {
        return kFailed;
    }

    // any unit near?
    if ( context.blackboard.closestEnemyInRange == nil ) {
        return kFailed;
    }
    
    // closest unit too far away?
    if ( ccpDistance( unit.position, context.blackboard.closestEnemyInRange.position) > unit.assaultRange ) {
        // too far away
        return kFailed;
    }

    // we can assault
    return kSucceeded;
}

@end
