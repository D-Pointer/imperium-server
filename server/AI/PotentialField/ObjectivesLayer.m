
#import "ObjectivesLayer.h"
#import "Globals.h"
#import "Objective.h"

@interface ObjectivesLayer () {
    ObjectiveState * oldStates;
}

@end


@implementation ObjectivesLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        // fill
        oldStates = 0;
    }
    return self;
}


- (void) dealloc {
    if ( oldStates != 0 ) {
        free( oldStates );
        oldStates = 0;
    }
}


- (void) update {
    int index;
    float value;

     NSMutableArray * objectives = [Globals sharedInstance].objectives;

    // have we set up the old states already? if so then we may not need to update this
    if ( oldStates != 0 ) {
        BOOL updateNeeded = NO;

        // compare states
        for ( index = 0; index < objectives.count; ++index ) {
            Objective * objective = [objectives objectAtIndex:index];
            if ( oldStates[ index ] != objective.state ) {
                // the values differ, so we need to update this layer
                updateNeeded = YES;
                break;
            }
        }

        // update needed?
        if ( ! updateNeeded ) {
            NSLog( @"no change in objectives layer, skipping update" );
            return;
        }
    }
    else {
        // first time called, so allocate the old states array
        oldStates = malloc( objectives.count * sizeof(ObjectiveState) );
    }

    // update all the new states that we'll set below
    for ( index = 0; index < objectives.count; ++index ) {
        Objective * objective = [objectives objectAtIndex:index];
        oldStates[ index ] = objective.state;
    }


    // clear all old data
    [self clear];

    // objective scoring:
    // neutral:    750
    // contested:  500
    // enemy:      250
    // own:        100

    // radius of the objective influence in tiles
    int radius = 500 / sParameters[kParamPotentialFieldTileSizeI].intValue;
    int manhattanRadius = radius * radius;

    // loop all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        int objectiveX = [self fromWorld:objective.position.x];
        int objectiveY = [self fromWorld:objective.position.y];

        // determine the value of the objective for the AI player
        if ( objective.state == kNeutral ) {
            value = 750;
        }
        else if ( objective.state == kContested ) {
            value = 500;
        }
        else if ( objective.state != [Globals sharedInstance].localPlayer.playerId ) {
            // enemy owned
            value = 250;
        }
        else {
            // own
            value = 100;
        }

        // center value
        index = objectiveY * self.width + objectiveX;
        data[ index ] += value;

        // new max?
        self.max = max( self.max, data[ index ] );

        int startX = MAX( 0, objectiveX - radius );
        int startY = MAX( 0, objectiveY - radius );
        int endX = MIN( self.width - 1, objectiveX + radius );
        int endY = MIN( self.height - 1, objectiveY + radius );

        // all hexes around get a bit influence
        for ( int y = startY; y <= endY; ++y ) {
            for ( int x = startX; x <= endX; ++x ) {
                // objective's own position?
                if ( x == objectiveX && y == objectiveY ) {
                    continue;
                }

                // distance from the objective
                float distance = (x - objectiveX) * (x - objectiveX) + (y - objectiveY) * (y - objectiveY); //sqrtf( (x - objectiveX) * (x - objectiveX) + (y - objectiveY) * (y - objectiveY) );

                // also inside the influence range?
                if ( distance < manhattanRadius ) {
                    // approximate a linearly decreasing value
                    float outsideValue = value - value * ( distance / manhattanRadius );

                    // add to the tile value
                    index = y * self.width + x;
                    data[ index ] += outsideValue;
                    //data[ index ] = MAX( outsideValue, data[ index ] );

                    // new max value?
                    if ( data[ index ] > self.max ) {
                        self.max = data[ index ];
                    }
                }
            }
        }
    }
}

@end
