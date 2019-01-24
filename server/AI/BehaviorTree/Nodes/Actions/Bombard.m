
#import "Bombard.h"
#import "FireMission.h"
#import "Globals.h"

@implementation Bombard

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );
    Unit * attacker = context.unit;

    float closestDistance = MAXFLOAT;
    Unit * closestEnemy = nil;

    Unit * hq = attacker.headquarter;

    // check all enemies that the unit's hq sees
    for ( unsigned int index = 0; index < hq.losData.seenCount; ++index ) {
        Unit * enemy = [hq.losData getSeenUnit:index];

        // distance to the target
        float distance = ccpDistance( attacker.position, enemy.position );

        // only check if closer that the closest so far
        if ( distance < closestDistance && distance <= attacker.weapon.firingRange ) {
            // we have an enemy in range, is it also inside the field of fire?
            if ( [attacker isInsideFiringArc:enemy.position checkDistance:NO] ) {
                // it's inside the firing arc too
                closestDistance = distance;
                closestEnemy = enemy;
            }
        }
    }

    if ( closestEnemy == nil ) {
        // nothing suitable after all
        return [self failed:context];
    }

    CCLOG( @"assigning new target %@", closestEnemy );

    // have it fire at the found target
    attacker.mission = [[FireMission alloc] initWithTarget:closestEnemy];

    // we're now an executed action
    context.blackboard.executedAction = self;

    // rule really matched
    return [self succeeded:context];
}


@end
