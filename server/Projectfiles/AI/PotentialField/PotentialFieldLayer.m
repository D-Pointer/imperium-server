
#import "PotentialFieldLayer.h"
#import "Globals.h"
#import "MapLayer.h"

@interface PotentialFieldLayer ()

@property (nonatomic, assign, readwrite) unsigned int dataSize;
@property (nonatomic, assign, readwrite) int          width;
@property (nonatomic, assign, readwrite) int          height;

@end


@implementation PotentialFieldLayer

- (id) init {
    if ( ( self = [super init] ) ) {
        // no sprite yet
        self.sprite = nil;

        Globals * globals = [Globals sharedInstance];

        // by default no colors
        colors = 0;

        //self.min = 0;
        self.max = 0;

        // size of the raw data array
        self.width  = [Globals sharedInstance].mapLayer.mapWidth / sParameters[kParamPotentialFieldTileSizeI].intValue;
        self.height = [Globals sharedInstance].mapLayer.mapHeight / sParameters[kParamPotentialFieldTileSizeI].intValue;

        // the raw 2D array
        self.dataSize = self.width * self.height * sizeof(float);
        data = (float *)malloc( self.dataSize );

        // reset all data to 0
        memset( data, 0x00, self.dataSize );

        CCLOG( @"map size: %d %d, potential field size: %d %d, bytes: %d", globals.mapLayer.mapWidth, globals.mapLayer.mapHeight, self.width, self.height, self.dataSize );
    }

    return self;
}


- (void) dealloc {
    if ( data ) {
        free( data );
        data = 0;
    }
    if ( colors ) {
        free( colors );
        colors = 0;
    }

    if ( self.sprite ) {
        [self.sprite removeFromParentAndCleanup:YES];
        self.sprite = nil;
    }
}


- (void) update {
    // nothing to do
}


- (void) applyTo:(PotentialFieldLayer *)target {
    float * layerData = [target getData];

    float min = 0;
    float max = 0;

    CCLOG( @"applying %@ to %@, source max: %.1f", self.class, target.class, self.max );

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

    if ( colors ) {
        // the real pixel size of the texture that gets used. it's likely larger, a POT texture
        int textureWidth  = (int)ccNextPOT( self.width * sParameters[kParamPotentialFieldPixelSizeI].intValue );
        int textureHeight = (int)ccNextPOT( self.height * sParameters[kParamPotentialFieldPixelSizeI].intValue );

        // allocate space for the colors
        unsigned int colorSize = textureWidth * textureHeight * sizeof(ccColor4B);
        memset( colors, 0x00, colorSize );
    }

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


- (void) updateDebugSprite {
    CCLOG( @"max: %.1f", self.max );

    // any old sprite?
    if ( self.sprite ) {
        [self.sprite removeFromParentAndCleanup:YES];
        self.sprite = nil;
    }

    // the real pixel size of the texture that gets used. it's likely larger, a POT texture
    int textureWidth  = (int)ccNextPOT( self.width * sParameters[kParamPotentialFieldPixelSizeI].intValue );
    int textureHeight = (int)ccNextPOT( self.height * sParameters[kParamPotentialFieldPixelSizeI].intValue );

    //CCLOG( @"texture size: %d x %d", textureWidth, textureHeight );

    // allocate space for the colors
    if ( colors == 0 ) {
        unsigned int colorSize = textureWidth * textureHeight * sizeof(ccColor4B);
        colors = (ccColor4B *)malloc( colorSize );
        //CCLOG( @"color size: %d", colorSize );
    }

    int pixelSize = sParameters[kParamPotentialFieldPixelSizeI].intValue;

    // create the texture data. most potential will be white, least will be black
    for ( int y = 0; y < self.height; ++y ) {
        for ( int x = 0; x < self.width; ++x ) {
            int dataIndex = y * self.width + x;

            // a grayscale color
            int color = data[ dataIndex ] / self.max * 255.0f;

            int textureIndex = (y * pixelSize) * textureWidth + x * pixelSize;

            // save the pixels. each field element will be sPotentialFieldPixelSize pixels wide and high
            for ( int tmpY = 0; tmpY < pixelSize; ++tmpY ) {
                for ( int tmpX = 0; tmpX < pixelSize; ++tmpX ) {
                    colors[ textureIndex + tmpX ] = ccc4( color, color, color, 255 );
                }

                textureIndex += textureWidth;
            }
        }
    }

    // create the raw texture from the color data
    CCTexture2D * texture = [[CCTexture2D alloc] initWithData:colors
                                                  pixelFormat:kCCTexture2DPixelFormat_RGBA8888
                                                   pixelsWide:textureWidth
                                                   pixelsHigh:textureHeight
                                                  contentSize:CGSizeMake( self.width * pixelSize, self.height * pixelSize )];
    [texture generateMipmap];
    
    // create a sprite from the the texture data
    self.sprite = [CCSprite spriteWithTexture:texture];
    self.sprite.flipY = YES;
}


@end
