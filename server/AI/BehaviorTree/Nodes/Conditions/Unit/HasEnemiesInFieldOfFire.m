
#import "HasEnemiesInFieldOfFire.h"
#import "LineOfSight.h"

@implementation HasEnemiesInFieldOfFire

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.blackboard.enemiesInFieldOfFire.count > 0 ) {
        return kSucceeded;
    }

    return kFailed;

//    int count = 0;
//    float closestDistance = MAXFLOAT;
//
//    Unit * unit = context.unit;

//    // check all enemies that the unit sees
//    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
//        Unit * enemy = [unit.losData getSeenUnit:index];
//        
//        // distance to the target
//        float distance = ccpDistance( unit.position, enemy.position );
//        if ( distance < closestDistance && distance <= unit.weapon.firingRange ) {
//            // we have an enemy in range, is it also inside the field of fire?
//            if ( [unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
//                // it's inside the firing arc too
//                count++;
//                closestDistance = distance;
//                context.blackboard.closestEnemyInFieldOfFire = enemy;
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
