
#import "Rally.h"
#import "LineOfSight.h"
#import "RallyMission.h"
#import "Globals.h"

@implementation Rally

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    // does it match?
    if ( conditions.unitConditions.canRally.isTrue ) {
        // conditions ok
        Unit * rallyTarget = conditions.unitConditions.canRally.foundUnit;
        NSAssert( rallyTarget != nil, @"rally target is nil" );

        CCLOG( @"%@ trying to assault %@", unit, rallyTarget );

        // all ok, set up a rallying missing
        unit.mission = [[RallyMission alloc] initWithTarget:rallyTarget];
        return YES;
    }

    return NO;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/Assault.png"];
}

@end
