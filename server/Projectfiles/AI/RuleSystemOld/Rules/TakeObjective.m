
#import "TakeObjective.h"
#import "PathFinder.h"
#import "Organization.h"
#import "MoveMission.h"
#import "ChangeModeMission.h"
#import "Globals.h"
#import "MapLayer.h"

@implementation TakeObjective

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    //CCLOG( @"checking rule %@ for unit %@", self, unit );

    // does it match?
    if ( conditions.organizationConditions.shouldTakeObjective.isTrue &&
        conditions.globalConditions.areAllObjectivesHeld.isFalse &&
        conditions.unitConditions.hasTarget.isFalse &&
        conditions.unitConditions.isFormationMode.isTrue &&
        conditions.unitConditions.hasMission.isFalse &&
        conditions.unitConditions.seesEnemies.isFalse ) {

        // is it a support unit?
        if ( conditions.unitConditions.isSupportUnit.isTrue ) {
            // it could support the advance by firing on something
            CCLOG( @"TODO: support unit takes objective?" );
            return NO;
        }
        else {
            return [self executeForUnit:unit];
        }

        return YES;
    }

    return NO;
}


- (BOOL) executeForUnit:(Unit *)unit {
    // do not advance there in column mode...
    if ( unit.mode == kColumn ) {
        CCLOG( @"only changing mode for the unit" );
        unit.mission = [ChangeModeMission new];
        return YES;
    }

    Organization * organization = unit.organization;
    
    // straigh line distance to the objective
    float distanceToObjective = ccpDistance( unit.position, organization.objective.position );

    // try a maximum of 10 times to find a location around the objective
    for ( int index = 0; index < 10; ++index ) {
        // a random angle and distance from the center
        float angle = CCRANDOM_0_1() * M_PI * 2;
        float distance = CCRANDOM_0_1() * 50.0f;

        // a position around the objective
        CGPoint pos = ccp( organization.objective.position.x + cosf( angle ) * distance,
                          organization.objective.position.y + sinf( angle ) * distance );


        // is the position still inside the map?
        if ( [[Globals sharedInstance].mapLayer isInsideMap:pos] ) {
            // still inside, so try to find a path there
            Path * path = [[Globals sharedInstance].pathFinder findPathFrom:unit.position to:pos forUnit:unit];
            if ( path == nil ) {
                continue;
            }

            // found a path, how long is it?
            if ( path.length > distanceToObjective * 2.0f ) {
                CCLOG( @"path is too long, not using" );
                continue;
            }

            // update the final facing for the path
            [path updateFinalFacing];

            // create the movement mission
            unit.mission = [[MoveMission alloc] initWithPath:path];
            
            // found a path
            return YES;
        }
    }

    // no path found
    return NO;
}


- (CCSprite *) createDebuggingNode {
    return [CCSprite spriteWithSpriteFrameName:@"AI/TakeObjective.png"];
}

@end
