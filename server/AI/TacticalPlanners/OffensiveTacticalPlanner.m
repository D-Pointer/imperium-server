
#import "OffensiveTacticalPlanner.h"
#import "RotateMission.h"

@implementation OffensiveTacticalPlanner

- (void) planForOrganization:(Organization *)organization {
    CCLOG( @"planning for organization %@", organization );

    // what should the organization do?
    switch ( organization.order ) {
        case kHold:
            [self holdPositionWith:organization];
            break;

        case kAdvanceTowardsEnemy:
            [self advanceWith:organization];
            break;

        case kTakeObjective:
            [self takeObjectiveWith:organization];
            break;
    }
}


- (void) planForIndependent:(Unit *)unit {
    CCLOG( @"planning for independent %@", unit );

    // TODO
}


- (void) holdPositionWith:(Organization *)organization {
    CCLOG( @"holding organization %@", organization );

    // simply have the units face the closest enemy
    for ( Unit * unit in organization.units ) {
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

        CCLOG( @"own: %@ has closest enemy %@ at %.1f m", unit, closestEnemy, closestDistance );

        // is the enemy not inside our firing arc?
        if ( closestDistance < sMaxAIFaceEnemyDistance ) {
            if ( [unit isInsideFiringArc:closestEnemy.position checkDistance:NO] == NO ) {
                //  closenope, so rotate to face it
                unit.mission = [[RotateMission alloc] initWithFacingTarget:closestEnemy.position
                                                              maxDeviation:unit.weapon.firingAngle / 2.0f - 5.0f];
                CCLOG( @"enemy is close enough, rotating to face" );
            }
            else {
                CCLOG( @"enemy is close enough and inside firing arc" );
            }
        }
    }
}


- (void) advanceWith:(Organization *)organization {
    CCLOG( @"advancing organization %@", organization );

    // find the nearest frontline for all units

    // average the angles to find a general angle of advancement

    // advance along angle using pathfinder
}


- (void) takeObjectiveWith:(Organization *)organization {
    CCLOG( @"taking objective %@ with organization %@", organization.objective.title, organization );


    // advance the hq to a position 50 m behind the objective

    // advance the first infantry or cavalry to the objective

    // advance all other infantry and cavalry in a fan around the objective

    // advance all artillery near the hq
}

@end
