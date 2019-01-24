
#import "EnemiesInfo.h"
#import "Unit.h"
#import "Organization.h"
#import "UnitContext.h"

@implementation EnemiesInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 10;
    }

    return self;
}


- (void) update:(UnitContext *)context {
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

    context.enemiesInRange            = enemiesInRange;
    context.enemiesInFieldOfFire      = enemiesInFieldOfFire;
    context.closestEnemyInRange       = closestEnemyInRange;
    context.closestEnemyInFieldOfFire = closestEnemyInFieldOfFire;

    CCLOG( @"units in range: %lu, units in field of fire: %lu", (unsigned long)enemiesInRange.count, (unsigned long)enemiesInFieldOfFire.count );
}

@end
