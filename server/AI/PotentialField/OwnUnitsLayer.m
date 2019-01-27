
#import "OwnUnitsLayer.h"
#import "Globals.h"
#import "Unit.h"

@implementation OwnUnitsLayer

- (void) update {
    int index;
    float influence, distance;

    // range of the unit's influence in tiles
    float influenceRange = 100.0f / sParameters[kParamPotentialFieldTileSizeI].intValue;
    float manhattanInfluenceRange = influenceRange * influenceRange;

    // clear all old data
    [self clearToValue:100];

    // loop all own (AI) units
    for ( Unit * unit in [Globals sharedInstance].unitsPlayer2 ) {
        int unitX = [self fromWorld:unit.position.x];
        int unitY = [self fromWorld:unit.position.y];

        int startX = MAX( 0, unitX - influenceRange );
        int startY = MAX( 0, unitY - influenceRange );
        int endX = MIN( self.width - 1, unitX + influenceRange );
        int endY = MIN( self.height - 1, unitY + influenceRange );

        // all positions around get a bit influence
        for ( int y = startY; y <= endY; ++y ) {
            for ( int x = startX; x <= endX; ++x ) {
                // manhattan distance from the unit
                distance = (x - unitX) * (x - unitX) + (y - unitY) * (y - unitY);

                // also inside the influence range? use manhattan distances
                if ( distance < manhattanInfluenceRange ) {
                    // approximate a linearly decreasing firepower
                    influence = 75 + 25 * ( distance / manhattanInfluenceRange );

                    index = y * self.width + x;
                    
                    // set the tile value to be the lowest of the current influence and the new
                    // the influences are not added!
                    if ( influence < data[ index ] ) {
                        data[ index ] = influence;
                    }
                }
            }
        }
    }

    NSLog( @"max: %.2f", self.max );
}

@end
