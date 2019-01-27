
#import "ObjectivesMap.h"
#import "Player.h"
#import "Unit.h"
#import "Globals.h"
#import "Objective.h"

@implementation ObjectivesMap

- (void) calculateMap {
}


- (id) init {
    if ( ( self = [super init] ) ) {
        self.title = @"Objectives";
	}
    
	return self;
}


- (void) update {
    [self clear];
    
    int index;
    float value;

    // objective scoring:
    // contested:  500
    // enemy:      250
    // own:        100

    // radius of the objective influence in tiles
    int radius = sObjectiveMaxDistance / self.tileSize;

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

        // new min or max?
        self.max = max( self.max, data[ index ] );

        // all hexes around get a bit influence
        for ( int y = objectiveY - radius; y <= objectiveY + radius; ++y ) {
            for ( int x = objectiveX - radius; x <= objectiveX + radius; ++x ) {
                // objective's own position?
                if ( x == objectiveX && y == objectiveY ) {
                    continue;
                }

                // check that the around position is inside the map
                if ( y >= 0 && y < self.height && x >= 0 && x < self.width ) {
                    // distance from the objective
                    float distance = sqrtf( (x - objectiveX) * (x - objectiveX) + (y - objectiveY) * (y - objectiveY) );
                    
                    // also inside the influence range?
                    if ( distance < radius ) {
                        // approximate a linearly decreasing firepower
                        float outsideValue = value - value * ( distance / radius );

                        // add to the tile value
                        index = y * self.width + x;
                        data[ index ] += outsideValue;

                        // new max value?
                        if ( data[ index ] > self.max ) {
                            self.max = data[ index ];
                        }
                    }
                }
            }
        }
    }

    NSLog( @"high: %f", self.max );

    // set up the colors
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int dataIndex = y * self.width + x;
            int textureIndex = y * self.textureWidth + x;

            // a grayscale color
            int color = ( data[ dataIndex ] / self.max * 255.0f );
            colors[ textureIndex ] = ccc4( 0, color, 0, 255 );
        }
    }
}

@end
