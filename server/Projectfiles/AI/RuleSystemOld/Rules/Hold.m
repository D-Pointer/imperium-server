
#import "Hold.h"
#import "Organization.h"

@implementation Hold

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.hasEnemiesInRange.isFalse &&
        conditions.organizationConditions.shouldHold.isTrue &&
        conditions.unitConditions.isFormationMode.isTrue &&
        conditions.unitConditions.hasMission.isFalse ) {

        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // do nothing
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/Hold.png"];
}

@end
