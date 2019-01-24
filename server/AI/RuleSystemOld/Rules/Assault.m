
#import "Assault.h"
#import "LineOfSight.h"
#import "AssaultMission.h"
#import "Globals.h"
#import "Engine.h"

@implementation Assault

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.hasEnemiesInFieldOfFire.isTrue &&
        conditions.unitConditions.isUnderFire.isFalse &&
        conditions.unitConditions.canAssault.isTrue ) {

        // conditions ok, try to find a target to assault
        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // find a good target
    Unit * target = [self findClosestTargetForUnit:unit];
    if ( ! target ) {
        CCLOG( @"did not find target even though rule matched");
        return NO;
    }

    // is the target weak enough?
    if ( unit.men <= target.men * 1.5f ) {
        CCLOG( @"target %@ is too strong, not assaulting", target );
        return NO;
    }

    CCLOG( @"%@ trying to assault %@", unit, target );

    // still inside, so try to find a path there
    Path * path = [[Globals sharedInstance].pathFinder findPathFrom:unit.position to:target.position forUnit:unit];
    if ( path == nil ) {
        CCLOG( @"did not find a path from %@ to %@, not assaulting", unit, target );
        return NO;
    }

    // have it fire at the found target
    unit.mission = [[AssaultMission alloc] initWithPath:path];

    return YES;
}


- (Unit *) findClosestTargetForUnit:(Unit *)attacker {
    Unit * bestTarget = nil;
    float bestDistance = 1000000;

    //NSSet * enemies = [[Globals sharedInstance].lineOfSight getEnemiesSeenBy:attacker];

    // check all the human player's units. An AI player will assign own targets and a remote online player
    // will do the same for his/her units
    for ( unsigned int index = 0; index < attacker.losData.seenCount; ++index ) {
        Unit * target = [attacker.losData getSeenUnit:index];

        // don't fire at own units or destroyed units
        if ( target.destroyed || target.owner == attacker.owner ) {
            continue;
        }

        // can't fire at what we don't see
        if ( target.visible == NO ) {
            continue;
        }

        // distance to the target
        float distance = ccpDistance( attacker.position, target.position );
        if ( distance > attacker.weapon.firingRange ) {
            // too far
            continue;
        }

        // inside the firing arc?
        if ( ! [attacker isInsideFiringArc:target.position checkDistance:YES] ) {
            // outside firing arc
            continue;
        }

        // better than the current best target?
        if ( distance < bestDistance ) {
            bestTarget = target;
            bestDistance = distance;
        }
    }
    
    return bestTarget;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/Assault.png"];
}

@end
