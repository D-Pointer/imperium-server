
#import "HasEnemiesInRange.h"
#import "LineOfSight.h"

@implementation HasEnemiesInRange

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.blackboard.enemiesInRange.count > 0 ) {
        return kSucceeded;
    }

    return kFailed;

//    int count = 0;
//    float closestDistance = MAXFLOAT;
//
//    Unit * unit = context.unit;
//
//    // check all enemies that the unit sees
//    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
//        Unit * enemy = [unit.losData getSeenUnit:index];
//
//        // distance to the target
//        float distance = ccpDistance( unit.position, enemy.position );
//        if ( distance <= unit.weapon.firingRange ) {
//            // we have an enemy in range
//            count++;
//             context.blackboard.ene
//            // new closest unit?
//            if ( distance < closestDistance ) {
//                closestDistance = distance;
//                context.blackboard.closestEnemyInRange = enemy;
//            }
//        }
//    }
//
//    if ( count > 0 ) {
//        return kSucceeded;
//    }
//
//    return kFailed;
}

@end
