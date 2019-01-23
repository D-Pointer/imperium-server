
#import "FrontLayer.h"
#import "Globals.h"

@implementation FrontLayer

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

    // center point. to the left full values, to the right gradient towards 0 at the right edge
    float center = self.width * 0.4f;

    for ( int y = 0; y <= self.height - 1; ++y ) {
        for ( int x = 0; x <= self.width - 1; ++x ) {
            if ( x < center ) {
                value = 1.0f;
            }
            else {
                value = 1.0f - (x - center) / (self.width - center);
            }

            // final value
            value *= 100;

            // potential value
            index = y * self.width + x;
            data[ index ] = value;

            self.max = MAX( self.max, value );
            // self.min = MIN( self.min, value );
        }
    }

    initialized = YES;
}

@end
