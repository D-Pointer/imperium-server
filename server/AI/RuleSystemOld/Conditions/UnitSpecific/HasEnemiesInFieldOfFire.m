
#import "HasEnemiesInFieldOfFire.h"
#import "LineOfSight.h"

@implementation HasEnemiesInFieldOfFire

- (void) update {
    int count = 0;
    float closestDistance = MAXFLOAT;

    // by default there is no suitable enemy
    self.foundUnit = nil;

    // check all enemies that the unit sees
    for ( unsigned int index = 0; index < self.unit.losData.seenCount; ++index ) {
        Unit * enemy = [self.unit.losData getSeenUnit:index];
        
        // distance to the target
        float distance = ccpDistance( self.unit.position, enemy.position );
        if ( distance < closestDistance && distance <= self.unit.weapon.firingRange ) {
            // we have an enemy in range, is it also inside the field of fire?
            if ( [self.unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
                // it's inside the firing arc too
                count++;
                closestDistance = distance;
                self.foundUnit = enemy;
            }
        }
    }

    self.value = [NSNumber numberWithInt:count];
    self.isTrue = count > 0;
}

@end
