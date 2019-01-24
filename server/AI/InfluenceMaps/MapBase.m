
#import "MapBase.h"
#import "Globals.h"
#import "MapLayer.h"

@interface MapBase ()

@property (nonatomic, readwrite) int width;
@property (nonatomic, readwrite) int height;
@property (nonatomic, readwrite) int textureWidth;
@property (nonatomic, readwrite) int textureHeight;
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
        self.width  = [Globals sharedInstance].mapLayer.mapWidth / self.tileSize;
        self.height = [Globals sharedInstance].mapLayer.mapHeight / self.tileSize;

        // the real pixel size of the texture that gets used. it's likely larger, a POT texture
        self.textureWidth  = (int)ccNextPOT( self.width * self.tileScale );
        self.textureHeight = (int)ccNextPOT( self.height * self.tileScale );

        data = (float *)malloc( self.width * self.height * sizeof(float) );

        unsigned int colorSize = self.textureWidth * self.textureHeight * sizeof(ccColor4B);
        colors = (ccColor4B *)malloc( colorSize );
        memset( colors, 0xff, colorSize );
        CCLOG( @"scale: %d, %d %d -> %d %d, bytes: %d", self.tileScale, self.width, self.height, self.textureWidth, self.textureHeight, colorSize );

        // reset all data to 0
        [self clear];
	}
    
	return self;
}


- (void) dealloc {
    CCLOG( @"in" );

    if ( data ) {
        free( data );
        data = 0;
    }

    if ( colors ) {
        free( colors );
        colors = 0;
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


- (void) setPixel:(ccColor4B)color x:(int)x y:(int)y {
    int textureIndex = (y * self.tileScale) * self.textureWidth + x * self.tileScale;

    // save the pixels
    for ( int tmpY = 0; tmpY < self.tileScale; ++tmpY ) {
        for ( int tmpX = 0; tmpX < self.tileScale; ++tmpX ) {
            colors[ textureIndex + tmpX ] = color;
        }

        textureIndex += self.textureWidth;
    }
}


- (CCSprite *) createSprite {
    // create the raw texture from the color data
    CCTexture2D * texture = [[CCTexture2D alloc] initWithData:colors
                                                  pixelFormat:kCCTexture2DPixelFormat_RGBA8888
                                                   pixelsWide:self.textureWidth
                                                   pixelsHigh:self.textureHeight
                                                  contentSize:CGSizeMake(self.width * self.tileScale, self.height * self.tileScale)];
    [texture generateMipmap];

    //    ccTexParams texParams = { GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT };
    //    [self.texture setTexParameters:&texParams];
    //    [self.texture setAliasTexParameters];
    //    [self.texture setAntiAliasTexParameters];
    // DEBUG

    // create a sprite from the the texture data
    CCSprite * sprite = [CCSprite spriteWithTexture:texture];
    sprite.flipY = YES;
    
    //sprite.blendFunc = (ccBlendFunc){ CC_BLEND_SRC, CC_BLEND_DST };
    //sprite.color = ccc3(255, 255, 255);
    
    return sprite;
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
