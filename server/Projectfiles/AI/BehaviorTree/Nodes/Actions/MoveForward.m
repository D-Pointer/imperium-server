
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

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    Unit * unit = context.unit;


    // the distance to move: 50-150 meters
    float distance = 50 + CCRANDOM_0_1() * 100.0f;

    CGPoint currentPos = unit.position;

    // the path given to the unit
    Path * path = [Path new];

    // add positions until the path is long enough
    while ( path.length < distance ) {
        CGPoint pos;
        if ( ! [context.potentialField findMaxPositionFrom:currentPos into:&pos] ) {
            // no pos found
            CCLOG( @"did not find a better position in the potential field" );
            return [self failed:context];
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

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}

@end
