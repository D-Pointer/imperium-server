
#import "FrontlineMap.h"
#import "Globals.h"

@interface FrontlineMap ()

@property (nonatomic, weak) InfluenceMap * map;

@end


@implementation FrontlineMap


- (id) initWithInfluenceMap:(InfluenceMap *)influenceMap {
    if ( ( self = [super init] ) ) {
        self.title = @"Frontlines";
        _map = influenceMap;
	}

	return self;
}


- (void) update {
    [self clear];

    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {

            // influence value of this hex
            float value = [self.map getValue:x y:y];
            float neighbour;
            
            BOOL front = NO;

            // left neighbour a front, i.e different sign?
            if ( x > 0 ) {
                neighbour = [self.map getValue:x - 1 y:y];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // right
            if ( front == NO && x < self.width - 1 ) {
                neighbour = [self.map getValue:x + 1 y:y];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            if ( front == NO && y > 0 ) {
                neighbour = [self.map getValue:x y:y - 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            if ( front == NO && y < self.height - 1 ) {
                neighbour = [self.map getValue:x y:y + 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // top left
            if ( front == NO && x > 0 && y > 0 ) {
                neighbour = [self.map getValue:x - 1 y:y - 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // top right
            if ( front == NO && x < self.width - 1 && y > 0 ) {
                neighbour = [self.map getValue:x + 1 y:y - 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // bottom right
            if ( front == NO && x < self.width - 1 && y < self.height - 1 ) {
                neighbour = [self.map getValue:x + 1 y:y + 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // bottom left
            if ( front == NO && x > 0 && y < self.height - 1 ) {
                neighbour = [self.map getValue:x - 1 y:y + 1];
                if ( (value < 0 && neighbour > 0 ) || (value > 0 && neighbour < 0 ) ) {
                    front = YES;
                }
            }

            // do we have both a negative and a positive neighbour?
            if ( front ) {
                // whose side?
                if ( value < 0 ) {
                    [self setPixel:ccc4( 100, 100, 255, 255 ) x:x y:y];
                }
                else {
                    [self setPixel:ccc4( 255, 50, 50, 255 ) x:x y:y];
                }
            }
            else {
                [self setPixel:ccc4( 0, 0, 0, 255 ) x:x y:y];
            }
        }
    }
}


@end
