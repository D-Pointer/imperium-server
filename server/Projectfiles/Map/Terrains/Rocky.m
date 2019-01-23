
#import "Rocky.h"

@implementation Rocky

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing {
    self = [super initWithPolygon:vertices];
    if (self) {
        // use custom z order
        self.mapLayerZ = kRockyZ;
    }

    return self;
}


- (void) createRocksFrom:(NSArray *)parts {
    // the size of the render texture
    int width = (int)( max_x - min_x );
    int height = (int)( max_y - min_y );
   
    CCRenderTexture * renderTexture = [CCRenderTexture renderTextureWithWidth:width height:height pixelFormat:kCCTexture2DPixelFormat_RGBA4444];

    // load the three trees and shadows
    CCSprite * rocks[7];
    rocks[0] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock1.png"];
    rocks[1] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock2.png"];
    rocks[2] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock3.png"];
    rocks[3] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock4.png"];
    rocks[4] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock5.png"];
    rocks[5] = [CCSprite spriteWithSpriteFrameName:@"Rocks/rock6.png"];

    [renderTexture begin];
    
    int created = 0;

    // the data is: id x y scale rotation
    for ( unsigned int index = 1; index < parts.count; index += 5 ) {
        int treeId     = [[parts objectAtIndex:index + 0] intValue];
        float x        = [[parts objectAtIndex:index + 1] floatValue];
        float y        = [[parts objectAtIndex:index + 2] floatValue];
        float scale    = [[parts objectAtIndex:index + 3] floatValue];
        float rotation = [[parts objectAtIndex:index + 4] floatValue];

        CCSprite * rock = rocks[ treeId ];
        rock.position = ccp( x - min_x, y - min_y );
        
        // scale and rotate a bit randomly
        rock.scale = scale;
        rock.rotation = rotation;

        // render into the texture
        [rock visit];

        created++;
    }

    if ( created == 0 ) {
        CCLOG( @"no rocks created!" );
    }

    // use the render texture's result sprite
    [renderTexture end];

    self.anchorPoint = ccp( 0, 0 );
    
    // position it at the min coordinates, as the texture is only as big as it needs to be to contain the
    // whole polygon
    renderTexture.position = ccp( min_x, min_y );

    // the anchor point is fubar. without this the texture is positioned off to the left and down, no idea why...
    renderTexture.anchorPoint = ccp( 0, 0 );
    renderTexture.sprite.anchorPoint = ccp( 0, 1 );
    [self addChild:renderTexture];
}


@end
