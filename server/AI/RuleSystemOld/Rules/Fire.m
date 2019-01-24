
#import "Fire.h"
#import "Organization.h"
#import "FireMission.h"
#import "Globals.h"
#import "Engine.h"

@implementation Fire

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.hasEnemiesInRange.isTrue &&
        conditions.unitConditions.isFormationMode.isTrue &&
        conditions.unitConditions.hasMission.isFalse ) {

        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // find a good target
    Unit * newTarget = [[Globals sharedInstance].engine findTarget:unit onlyInsideArc:NO];
    if ( ! newTarget ) {
        CCLOG( @"did not find target for %@ even though rule matched", unit );
        return NO;
    }

//    Mission * oldMission = unit.mission;
//    Unit * oldTarget = nil;
//    if ( oldMission && [oldMission isKindOfClass:[CombatMission class]] ) {
//        oldTarget = ((CombatMission *)oldMission).targetUnit;
//    }
//
//    // did we get a new target?
//    if ( oldTarget != nil && newTarget == oldTarget ) {
//        CCLOG( @"best target still the old target, doing nothing" );
//        return NO;
//    }

    CCLOG( @"assigning new target %@", newTarget );

    // have it fire at the found target
    unit.mission = [[FireMission alloc] initWithTarget:newTarget];

    // rule really matched
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/Fire.png"];
}

@end
