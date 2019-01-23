
#import "TerrainLayer.h"
#import "Globals.h"
#import "PathFinder.h"

@implementation TerrainLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        initialized = NO;
    }

    return self;
}


- (void) update {
    // we do this only once ever
    if ( initialized ) {
        return;
    }

    //self.min = 0;
    self.max = 0;

    // cache the path finder
    PathFinder * pathFinder = [Globals sharedInstance].pathFinder;

    int index;
    float value;

    for ( int y = 0; y <= self.height - 1; ++y ) {
        for ( int x = 0; x <= self.width - 1; ++x ) {
            // type of terrain
            TerrainType terrain = [pathFinder getTerrainAtX:x y:y];

            // potential value
            value = [self potentialForTerrain:terrain];
            index = y * self.width + x;
            data[ index ] = value;

            self.max = MAX( self.max, value );
            //self.min = MIN( self.min, value );
        }
    }

    // a new array for data that is smoothed a bit
    float * smoothedData = (float *)malloc( self.dataSize );

    int startX, startY, endX, endY;

    //int radius = 2;

    // loop the generated data once more
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            startX = MAX( 0, x - 2 );
            startY = MAX( 0, y - 2 );
            endX = MIN( self.width - 1, x + 2 );
            endY = MIN( self.height - 1, y + 2 );

            float sum = 0;
            int count = 0;

            // loop all positions around the position and sum them up
            for ( int tmpY = startY; tmpY <= endY; ++tmpY ) {
                for ( int tmpX = startX; tmpX <= endX; ++tmpX ) {
                    sum += data[ tmpY * self.width + tmpX ];
                    count++;
                }
            }

            // average the data
            smoothedData[ y * self.width + x ] = sum / count;
        }
    }

    // get rid of the old data and use the smoothed data
    free( data );
    data = smoothedData;

    initialized = YES;
}


- (float) potentialForTerrain:(TerrainType)terrain {
    switch ( terrain ) {
        case kWoods:
            return 75;
        case kField:
            return 100;
        case kGrass:
            return 100;
        case kRoad:
            return 100;
        case kRiver:
            return 10;
        case kRoof:
            return 10;
        case kSwamp:
            return 70;
        case kRocky:
            return 10;
        case kBeach:
            return 80;
        case kFord:
            return 80;
        case kScatteredTrees:
            return 90;
        case kNoTerrain:
            return 10;
    }
}

@end
