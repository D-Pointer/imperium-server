
#import "EnemyLayer.h"
#import "Globals.h"
#import "Unit.h"

@implementation EnemyLayer


- (void) update {
    float influenceRange;

    self.max = 0;
    //self.min = 0;

    // clear all old data
    [self clear];

    int potentialFieldTileSize = sParameters[kParamPotentialFieldTileSizeI].intValue;

    // loop all units
    for ( Unit * unit in [Globals sharedInstance].unitsPlayer1 ) {
        // range of the unit's influence in tiles. add in some extra
        switch ( unit.type ) {
            case kInfantry:
                influenceRange = unit.weapon.firingRange * 3.0f / potentialFieldTileSize;
                break;
            case kCavalry:
                influenceRange = unit.weapon.firingRange * 4.0f / potentialFieldTileSize;
                break;
            case kArtillery:
                influenceRange = unit.weapon.firingRange * 3.0f / potentialFieldTileSize;
                break;
            case kInfantryHeadquarter:
                influenceRange = unit.weapon.firingRange * 4.0f / potentialFieldTileSize;
                break;
            case kCavalryHeadquarter:
                influenceRange = unit.weapon.firingRange * 5.0f / potentialFieldTileSize;
                break;
        }

        // where it stands it has full firepower
        float maxFirepower = unit.weaponCount * unit.weapon.firepower * 5;

        NSLog( @"%@ range: %f, max: %f", unit, influenceRange, maxFirepower );

        int unitX = [self fromWorld:unit.position.x];
        int unitY = [self fromWorld:unit.position.y];

        //NSLog( @"pos: %d %d", unitX, unitY );

        int startX = MAX( 0, unitX - influenceRange );
        int startY = MAX( 0, unitY - influenceRange );
        int endX = MIN( self.width - 1, unitX + influenceRange );
        int endY = MIN( self.height - 1, unitY + influenceRange );

        // all positions around get a bit influence
        for ( int y = startY; y <= endY; ++y ) {
            for ( int x = startX; x <= endX; ++x ) {
                // unit's own position?
                if ( x == unitX && y == unitY ) {
                    // add to the tile value
                    int index = y * self.width + x;
                    data[ index ] += maxFirepower;

                    // new max value?
                    self.max = max( self.max, data[ index ] );
                }

                else {
                    // distance from the unit
                    float distance = sqrtf( (x - unitX) * (x - unitX) + (y - unitY) * (y - unitY) );

                    // also inside the influence range? use manhattan distances
                    if ( distance < influenceRange ) {
                        // approximate a linearly decreasing firepower
                        float firepower = maxFirepower - maxFirepower * ( distance / influenceRange );

                        // add to the tile value
                        int index = y * self.width + x;
                        data[ index ] += firepower;

                        // new max value?
                        self.max = max( self.max, data[ index ] );
                    }
                }
            }
        }
    }
}

@end
