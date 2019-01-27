
#import "UnitStrengthMap.h"
#import "Player.h"
#import "Unit.h"
#import "Globals.h"

@implementation UnitStrengthMap


- (id) initForPlayer:(PlayerId)player withTitle:(NSString *)title_ {
    if ( ( self = [super init] ) ) {
        self.playerId = player;
        self.title    = title_;
	}
    
	return self;
}


- (void) update {
    [self clear];
    
    float influenceRange;

    self.max = 0;
    self.min = 0;

    // loop all units
    for ( Unit * unit in [Globals sharedInstance].units ) {
        // right owner?
        if ( unit.owner != self.playerId ) {
            continue;
        }

        // range of the unit's influence in tiles. add in some extra
        switch ( unit.type ) {
            case kInfantry:
                influenceRange = unit.weapon.firingRange * 1.75f / self.tileSize;
                break;
            case kCavalry:
                influenceRange = unit.weapon.firingRange * 2.0f / self.tileSize;
                break;
            case kArtillery:
                influenceRange = unit.weapon.firingRange * 1.5f / self.tileSize;
                break;
            case kInfantryHeadquarter:
                influenceRange = unit.weapon.firingRange * 2.0f / self.tileSize;
                break;
            case kCavalryHeadquarter:
                influenceRange = unit.weapon.firingRange * 2.5f / self.tileSize;
                break;
        }

        // where it stands it has full firepower
        float maxFirepower = [unit getBaseCasualtiesForRange:0];

        NSLog( @"%@ range: %f, max: %f", unit, influenceRange, maxFirepower );

        int unitX = [self fromWorld:unit.position.x];
        int unitY = [self fromWorld:unit.position.y];

        //NSLog( @"pos: %d %d", unitX, unitY );

        // all positions around get a bit influence
        for ( int y = unitY - influenceRange; y <= unitY + influenceRange; ++y ) {
            for ( int x = unitX - influenceRange; x <= unitX + influenceRange; ++x ) {
                // unit's own position?
                if ( x == unitX && y == unitY ) {
                    // add to the tile value
                    int index = y * self.width + x;
                    data[ index ] += maxFirepower;

                    // new max value?
                    self.max = max( self.max, data[ index ] );
                }

                else {
                    // check that the around position is inside the map
                    if ( y >= 0 && y < self.height && x >= 0 && x < self.width ) {
                        // distance from the unit
                        float distance = sqrtf( (x - unitX) * (x - unitX) + (y - unitY) * (y - unitY) );

                        // also inside the influence range? use manhattan distances
                        if ( distance < influenceRange ) {
                            // approximate a linearly decreasing firepower
                            float firepower = maxFirepower - maxFirepower * ( distance / influenceRange ); //* sqrtf( manhattan ) / (influenceRange * influenceRange) );

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

    NSLog( @"max: %f, min: %f", self.max, self.min );

    // create the texture data. most influence will be white, least will be black
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int dataIndex = y * self.width + x;

            // a grayscale color
            int color = ( data[ dataIndex ] / self.max * 255.0f );
            [self setPixel:ccc4( color, color, color, 255 ) x:x y:y];
        }
    }
}


@end
