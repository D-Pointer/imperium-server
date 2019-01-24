
#import "DefensiveTacticalPlanner.h"
#import "RotateMission.h"

@implementation DefensiveTacticalPlanner

- (void) planForOrganization:(Organization *)organization {
    CCLOG( @"planning for organization %@", organization );

    // simply have the units face the closest enemy
    for ( Unit * unit in organization.units ) {
        [self planForUnit:unit];
    }
}


- (void) planForIndependent:(Unit *)unit {
    CCLOG( @"planning for independent %@", unit );
    [self planForUnit:unit];
}


- (void) planForUnit:(Unit *)unit {
    CCLOG( @"planning for unit %@", unit );

    // simply have the unit face the closest enemy
    float closestDistance = 100000.0f;
    Unit * closestEnemy = nil;

    /// compare with all enemies
    for ( Unit * enemy in self.strategicPlanner.enemyUnits ) {
        float distance = ccpDistance( unit.position, enemy.position );
        if ( distance < closestDistance ) {
            // new closest enemy
            closestEnemy = enemy;
            closestDistance = distance;
        }
    }

    // we really should have found an enemy here
    NSAssert( closestEnemy, @"No enemy found" );

    // is the enemy not inside our firing arc?
    if ( closestDistance < sMaxAIFaceEnemyDistance ) {
        CCLOG( @"own: %@ has closest enemy %@ at %.0fm", unit, closestEnemy, closestDistance );

        if ( [unit isInsideFiringArc:closestEnemy.position checkDistance:NO] == NO ) {
            // nope, so rotate to face it
            unit.mission = [[RotateMission alloc] initWithFacingTarget:closestEnemy.position
                                                          maxDeviation:unit.weapon.firingAngle / 2.0f - 5.0f];
            CCLOG( @"enemy is close enough, rotating to face" );
        }
        else {
            CCLOG( @"enemy is close enough and inside firing arc" );
        }
    }
    else {
        // no enemy close enough
        CCLOG( @"own: %@ has closest enemy %@ at %.0fm, no action", unit, closestEnemy, closestDistance );
    }
}

@end
