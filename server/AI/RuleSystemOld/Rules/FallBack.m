
#import "FallBack.h"
#import "Organization.h"
#import "RetreatMission.h"
#import "MapLayer.h"
#import "AI.h"
#import "PotentialField.h"

@implementation FallBack

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    // retreat if we've taken damage and too many fire
    if ( conditions.unitConditions.isFullStrength.isFalse &&

        // not already retreating
        conditions.unitConditions.hasMission.missionType != kRetreatMission &&

        // not already routing
        conditions.unitConditions.hasMission.missionType != kRoutMission &&

        // nor assaulting
        conditions.unitConditions.hasMission.missionType != kAssaultMission &&

        // check morale
        [conditions.unitConditions.morale.value floatValue] < 60 &&

        // under fire by at least 3 enemies
        conditions.unitConditions.isUnderFire.isTrue &&
        [conditions.unitConditions.isUnderFire.value intValue] >= 3 ) {

        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // the distance to fall back: 50-150 meters
    float distance = 100 + CCRANDOM_0_1() * 100.0f;

    CGPoint currentPos = unit.position;

    // the path given to the unit
    Path * path = [Path new];

    // add positions until the path is long enough
    while ( path.length < distance ) {
        CGPoint pos;
        if ( ! [[Globals sharedInstance].ai.potentialField findMinThreatPositionFrom:currentPos into:&pos] ) {
            // no pos found
            CCLOG( @"did not find a minimum threat position in the potential field, trying old path finder" );
            return NO;
        }

        // add to the path
        [path addPosition:pos];

        CCLOG( @"positions: %lu length: %.1f", (unsigned long)path.count, path.length );
        currentPos = pos;
    }

    CCLOG( @"found potential field path, length: %.0f (min: %.0f)", path.length, distance );

    // DEBUG
    if ( sAIDebugging ) {
        [path debugPath];
    }

    // make a retreat mission of it
    unit.mission = [[RetreatMission alloc] initWithPath:path];

    // found a path
    return YES;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/FallBack.png"];
}

@end
