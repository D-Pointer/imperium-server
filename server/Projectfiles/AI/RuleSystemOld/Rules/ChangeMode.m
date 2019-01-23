
#import "ChangeMode.h"
#import "Organization.h"
#import "ChangeModeMission.h"

@implementation ChangeMode

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.isColumnMode.isTrue &&
        conditions.globalConditions.isBeginningOfGameCondition.isFalse &&
        conditions.unitConditions.hasMission.isFalse ) {
        
        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    unit.mission = [ChangeModeMission new];
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/ChangeMode.png"];
}


@end
