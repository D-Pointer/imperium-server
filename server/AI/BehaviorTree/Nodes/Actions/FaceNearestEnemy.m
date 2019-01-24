
#import "FaceNearestEnemy.h"
#import "Organization.h"
#import "LineOfSight.h"
#import "RotateMission.h"

@implementation FaceNearestEnemy

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    // check all enemies that the unit sees
    // check all the human player's units. An AI player will assign own targets and a remote online player
    // will do the same for his/her units
    //NSSet * enemies = [[Globals sharedInstance].lineOfSight getEnemiesSeenBy:unit];

    Unit * unit = context.unit;

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
        return [self failed:context];
    }

    // is the target already in our FOV?
    if ( [unit isInsideFiringArc:bestTarget.position checkDistance:NO] ) {
        // already inside, this rule does not apply then
        return [self failed:context];
    }

    // not inside FOV, rotate to face it
    unit.mission = [[RotateMission alloc] initFacingTarget:bestTarget.position];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}



@end
