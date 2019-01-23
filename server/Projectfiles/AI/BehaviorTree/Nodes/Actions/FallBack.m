
#import "FallBack.h"
#import "Globals.h"
#import "RetreatMission.h"
#import "MapLayer.h"
#import "AI.h"
#import "PotentialField.h"

@implementation FallBack

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    CCLOG( @"processing node %@", self );

    // the distance to fall back: 50-150 meters
    float distance = 100 + CCRANDOM_0_1() * 100.0f;

    Unit * unit = context.unit;
    CGPoint currentPos = unit.position;

    // the path given to the unit
    Path * path = [Path new];

    // add positions until the path is long enough
    while ( path.length < distance ) {
        CGPoint pos;
        if ( ! [context.potentialField findMinThreatPositionFrom:currentPos into:&pos] ) {
            // no pos found
            CCLOG( @"did not find a minimum threat position in the potential field, trying old path finder" );
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

    // make a retreat mission of it
    unit.mission = [[RetreatMission alloc] initWithPath:path];

    // we're now an executed action
    context.blackboard.executedAction = self;
    return [self succeeded:context];
}


@end
