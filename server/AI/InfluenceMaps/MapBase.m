
#import "MapBase.h"
#import "Globals.h"
#import "Scenario.h"

@interface MapBase ()

@property (nonatomic, readwrite) int width;
@property (nonatomic, readwrite) int height;
@property (nonatomic, readwrite) int tileSize;
@property (nonatomic, readwrite) int tileScale;

@end


@implementation MapBase

- (id) init {
    if ( ( self = [super init] ) ) {
        // one tile represents 20 x 20 m and will be 2x2 px
        self.tileSize = 20;
        self.tileScale = 2;

        // size of the raw data array
        self.width  = [Globals sharedInstance].scenario.width / self.tileSize;
        self.height = [Globals sharedInstance].scenario.height / self.tileSize;

        data = (float *)malloc( self.width * self.height * sizeof(float) );
        NSLog( @"scale: %d, %d %d", self.tileScale, self.width, self.height);

        // reset all data to 0
        [self clear];
	}
    
	return self;
}


- (void) dealloc {
    NSLog( @"in" );

    if ( data ) {
        free( data );
        data = 0;
    }
}


- (float) getValue: (int)x y:(int)y {
    return data[ y * self.width + x ];
}


- (float) getValue:(CGPoint)pos {
    // first convert the position to our internal reduced coordinate system
    int x = pos.x / self.tileSize;
    int y = pos.y / self.tileSize;
    return data[ y * self.width + x ];
}


- (void) addValue:(float)value index:(int)index {
    data[ index ] += value;    
    
    // new max value?
    if ( data[ index ] > self.max ) {
        self.max = data[ index ];
    }

    // new min value?
    if ( data[ index ] < self.min ) {
        self.min = data[ index ];
    }
}


- (void) clear {
    // reset all data to 0
    for ( int index = 0; index < self.width * self.height; ++index ) {
        data[ index ] = 0;
    }

    self.max = 0;
    self.min = 0;
}


- (int) fromWorld:(float)value {
    return (int)( value / self.tileSize );
}

@end
