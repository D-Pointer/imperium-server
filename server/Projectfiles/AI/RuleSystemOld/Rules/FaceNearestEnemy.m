
#import "FaceNearestEnemy.h"
#import "Organization.h"
#import "LineOfSight.h"
#import "RotateMission.h"

@implementation FaceNearestEnemy

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.isFormationMode.isTrue &&
        conditions.unitConditions.seesEnemies.isTrue &&
        conditions.unitConditions.hasEnemiesInRange.isFalse &&
        conditions.unitConditions.hasMission.isFalse ) {

        return [self executeForUnit:unit];
    }
    
    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // check all enemies that the unit sees
    // check all the human player's units. An AI player will assign own targets and a remote online player
    // will do the same for his/her units
    //NSSet * enemies = [[Globals sharedInstance].lineOfSight getEnemiesSeenBy:unit];

    Unit * bestTarget = nil;
    float bestDistance = 1000000;

    for ( unsigned int index = 0; index < unit.losData.seenCount; ++index ) {
        Unit * target = [unit.losData getSeenUnit:index];

        // don't fire at own units or destroyed units
        if ( target.destroyed || target.owner == unit.owner ) {
            continue;
        }

        // new closest enemy?
        float distance = ccpDistance( unit.position, target.position );
        if ( distance < bestDistance ) {
            bestTarget = target;
            bestDistance = distance;
        }
    }

    // did we find a target?
    if ( bestTarget == nil ) {
        // no suitable target found
        return NO;
    }

    // is the target already in our FOV?
    if ( [unit isInsideFiringArc:bestTarget.position checkDistance:NO] ) {
        // already inside, this rule does not apply then
        return NO;
    }

    // not inside FOV, rotate to face it
    unit.mission = [[RotateMission alloc] initFacingTarget:bestTarget.position];
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/FaceNearestEnemy.png"];
}


@end
