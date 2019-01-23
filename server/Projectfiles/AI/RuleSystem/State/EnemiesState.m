
#import "EnemiesState.h"
#import "Unit.h"
#import "Organization.h"

@implementation EnemiesState

- (void) update:(UnitContext *)context forRuleSystem:(GKRuleSystem *)ruleSystem {
    float closestInRangeDistance = MAXFLOAT;
    float closestInFieldOfFireDistance = MAXFLOAT;

    Unit * unit = context.unit;

    NSMutableArray * enemiesInRange = [NSMutableArray new];
    NSMutableArray * enemiesInFieldOfFire = [NSMutableArray new];
    Unit * closestEnemyInRange = nil;
    Unit * closestEnemyInFieldOfFire = nil;

    // check all enemies that the unit sees
    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
        Unit * enemy = [unit.losData getSeenUnit:index];

        // distance to the target
        float distance = ccpDistance( unit.position, enemy.position );

        // inside firing range?
        if ( distance <= unit.weapon.firingRange ) {
            [enemiesInRange addObject:enemy];

            // new closest in range?
            if ( distance < closestInRangeDistance ) {
                closestInRangeDistance = distance;
                closestEnemyInRange = enemy;
            }

            // inside field of fire?
            if ( [unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
                [enemiesInFieldOfFire addObject:enemy];

                // new closest in field of fire?
                if ( distance < closestInFieldOfFireDistance ) {
                    closestInFieldOfFireDistance = distance;
                    closestEnemyInFieldOfFire = enemy;
                }
            }
        }
    }

    ruleSystem.state[ @"enemiesInRange" ]            = enemiesInRange;
    ruleSystem.state[ @"enemiesInFieldOfFire" ]      = enemiesInFieldOfFire;
    ruleSystem.state[ @"closestEnemyInRange" ]       = closestEnemyInRange;
    ruleSystem.state[ @"closestEnemyInFieldOfFire" ] = closestEnemyInFieldOfFire;

    NSLog( @"units in range: %lu, units in field of fire: %lu", (unsigned long)enemiesInRange.count, (unsigned long)enemiesInFieldOfFire.count );
}

@end
