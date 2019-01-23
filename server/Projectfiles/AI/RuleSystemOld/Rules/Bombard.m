
#import "Bombard.h"
#import "FireMission.h"
#import "Globals.h"

@implementation Bombard

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    if ( conditions.unitConditions.isIndirectFireUnit.isTrue && // indirect fire unit
        conditions.unitConditions.isFormationMode.isTrue && // that is in formation mode ready to fire
        conditions.unitConditions.hasEnemiesInFieldOfFire.isTrue && // with enemies in the field of fire
        conditions.unitConditions.seesEnemies.isFalse && // that we don't see
        conditions.unitConditions.hasHq && // but we have a hq
        unit.headquarter.losData.seenCount > 0 ) { // that sees enemies
        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    float closestDistance = MAXFLOAT;
    Unit * closestEnemy = nil;

    Unit * hq = unit.headquarter;

    // check all enemies that the unit's hq sees
    for ( unsigned int index = 0; index < hq.losData.seenCount; ++index ) {
        Unit * enemy = [hq.losData getSeenUnit:index];

        // distance to the target
        float distance = ccpDistance( unit.position, enemy.position );

        // only check if closer that the closest so far
        if ( distance < closestDistance && distance <= unit.weapon.firingRange ) {
            // we have an enemy in range, is it also inside the field of fire?
            if ( [unit isInsideFiringArc:enemy.position checkDistance:NO] ) {
                // it's inside the firing arc too
                closestDistance = distance;
                closestEnemy = enemy;
            }
        }
    }

    if ( closestEnemy == nil ) {
        // nothing suitable after all
        return NO;
    }

    CCLOG( @"assigning new target %@", closestEnemy );

    // have it fire at the found target
    unit.mission = [[FireMission alloc] initWithTarget:closestEnemy];

    // rule really matched
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/Fire.png"];
}

@end
