
#import "PotentialFieldLayer.h"
#import "Globals.h"
#import "Map.h"

@interface PotentialFieldLayer ()

@property (nonatomic, assign, readwrite) unsigned int dataSize;
@property (nonatomic, assign, readwrite) int          width;
@property (nonatomic, assign, readwrite) int          height;

@end


@implementation PotentialFieldLayer

- (id) init {
    if ( ( self = [super init] ) ) {
        Globals * globals = [Globals sharedInstance];

        //self.min = 0;
        self.max = 0;

        // size of the raw data array
        self.width  = [Globals sharedInstance].map.mapWidth / sParameters[kParamPotentialFieldTileSizeI].intValue;
        self.height = [Globals sharedInstance].map.mapHeight / sParameters[kParamPotentialFieldTileSizeI].intValue;

        // the raw 2D array
        self.dataSize = self.width * self.height * sizeof(float);
        data = (float *)malloc( self.dataSize );

        // reset all data to 0
        memset( data, 0x00, self.dataSize );

        NSLog( @"map size: %d %d, potential field size: %d %d, bytes: %d", globals.map.mapWidth, globals.map.mapHeight, self.width, self.height, self.dataSize );
    }

    return self;
}


- (void) dealloc {
    if ( data ) {
        free( data );
        data = 0;
    }
}


- (void) update {
    // nothing to do
}


- (void) applyTo:(PotentialFieldLayer *)target {
    float * layerData = [target getData];

    float min = 0;
    float max = 0;

    NSLog( @"applying %@ to %@, source max: %.1f", self.class, target.class, self.max );

    // just add the values
    for ( int index = 0; index < self.width * self.height; ++index ) {
        // add the layer contribution, max possible value is the weight
        layerData[ index ] += data[ index ] / self.max * self.weight;

        // update the target max and min
        min = MIN( layerData[ index ], min );
        max = MAX( layerData[ index ], max );
    }

    //target.min = min;
    target.max = max;
}


- (float *) getData {
    return data;
}


- (void) clear {
    // reset all data to 0
    memset( data, 0x00, self.dataSize );

    //self.min = 0;
    self.max = 0;
}


- (void) clearToValue:(float)value {
    // loop and set the value
    for ( int index = 0; index < self.width * self.height; ++index ) {
        data[ index ] = value;
    }

    //self.min = value;
    self.max = value;
}


- (float) getValue:(CGPoint)pos {
    // first convert the position to our internal reduced coordinate system
    int x = pos.x / sParameters[kParamPotentialFieldTileSizeI].intValue;
    int y = pos.y / sParameters[kParamPotentialFieldTileSizeI].intValue;

    // return the data
    return data[ y * self.width + x ];
}


- (int) fromWorld:(float)value {
    return (int)( value / (float)sParameters[kParamPotentialFieldTileSizeI].intValue );
}


@end
