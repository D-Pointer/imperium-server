
#import "MoveForward.h"
#import "Organization.h"
#import "ChangeModeMission.h"
#import "MoveMission.h"
#import "MoveFastMission.h"
#import "Globals.h"
#import "MapLayer.h"
#import "AI.h"
#import "PotentialField.h"

@implementation MoveForward

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.unitConditions.isFormationMode.isTrue &&
        conditions.globalConditions.isDefendScenarioCondition.isFalse &&
        conditions.unitConditions.hasMission.isFalse &&
        conditions.unitConditions.isUnderFire.isFalse ) {

        return [self executeForUnit:unit];
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // the distance to move: 50-150 meters
    float distance = 50 + CCRANDOM_0_1() * 100.0f;

    CGPoint currentPos = unit.position;

    // the path given to the unit
    Path * path = [Path new];

    // add positions until the path is long enough
    while ( path.length < distance ) {
        CGPoint pos;
        if ( ! [[Globals sharedInstance].ai.potentialField findMaxPositionFrom:currentPos into:&pos] ) {
            // no pos found
            CCLOG( @"did not find a better position in the potential field, trying old path finder" );
            return [self findPathForUnit:unit];
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
    
    // create a mission based on the mode
    if ( unit.mode == kColumn ) {
        unit.mission = [[MoveFastMission alloc] initWithPath:path];
    }
    else {
        unit.mission = [[MoveMission alloc] initWithPath:path];
    }

    // found a path
    return YES;
}


- (BOOL) findPathForUnit:(Unit *)unit {
    // the distance to move: 50-150 meters
    float distance = 50 + CCRANDOM_0_1() * 100.0f;

    int angles[] = { 0, 10, -10, 20, -20, 30, -30, 40, -40, 50, -50, 60, -60, 70, -70 };

    for ( int angleIndex = 0; angleIndex < 15; ++angleIndex ) {
        int angle = angles[ angleIndex ];
        // a vector that's some distance straight behind the retreater
        CGPoint pos = ccpAdd( ccpMult( ccpForAngle( CC_DEGREES_TO_RADIANS( 180 - angle)), distance ), unit.position );

        CCLOG( @"delta: %.0f %.0f", pos.x, pos.y );

        // is the position still inside the map?
        if ( [[Globals sharedInstance].mapLayer isInsideMap:pos] ) {
            // still inside, so try to find a path there
            Path * path = [[Globals sharedInstance].pathFinder findPathFrom:unit.position to:pos forUnit:unit];
            if ( path == nil ) {
                continue;
            }

            // found a path, how long is it?
            if ( path.length > distance * 2.0f ) {
                CCLOG( @"path is too long, not using" );
                continue;
            }

            // create a mission based on the mode
            if ( unit.mode == kColumn ) {
                unit.mission = [[MoveFastMission alloc] initWithPath:path];
            }
            else {
                unit.mission = [[MoveMission alloc] initWithPath:path];
            }

            // found a path
            return YES;
        }
    }
    
    // nothing found
    return NO;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/MoveForward.png"];
}

@end
