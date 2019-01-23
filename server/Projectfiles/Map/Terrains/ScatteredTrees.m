
#import "ScatteredTrees.h"
#import "Globals.h"
#import "MapLayer.h"

// this is a margin around the polygon that allows the trees to reach outside the
// raw polygon boundaries and avoids them being clipped. the tree icons are all 30x30 px
static const int woodsMargin = 15;

@implementation ScatteredTrees

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing {
    self = [super initWithPolygon:vertices];
    if (self) {
        // use custom z order
        self.mapLayerZ = kScatteredTreesZ;
    }

    return self;
}


- (void) createTreesFrom:(NSArray *)parts {    
    // the size of the render texture
    int width = (int)( max_x - min_x );
    int height = (int)( max_y - min_y );

    // add in a margin
    width += woodsMargin * 2;
    height += woodsMargin * 2;

    CCRenderTexture * renderTexture = [CCRenderTexture renderTextureWithWidth:width height:height pixelFormat:kCCTexture2DPixelFormat_RGBA4444];

    // load the three trees and shadows
    CCSprite * trees[5];
    CCSprite * shadows[5];
    trees[0] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree1.png"];
    trees[1] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree2.png"];
    trees[2] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree3.png"];
    trees[3] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree4.png"];
    trees[4] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree5.png"];
    shadows[0] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree1_shadow.png"];
    shadows[1] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree2_shadow.png"];
    shadows[2] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree3_shadow.png"];
    shadows[3] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree4_shadow.png"];
    shadows[4] = [CCSprite spriteWithSpriteFrameName:@"Trees/tree5_shadow.png"];

    [renderTexture begin];
    
    int created = 0;

    int shadowOffsetX = 3;
    int shadowOffsetY = -3;

    // first the shadows so that they all come under the trees
    // the data is: id x y scale rotation
    for ( unsigned int index = 1; index < parts.count; index += 5 ) {
        int treeId     = [[parts objectAtIndex:index + 0] intValue];
        float x        = [[parts objectAtIndex:index + 1] floatValue];
        float y        = [[parts objectAtIndex:index + 2] floatValue];
        float scale    = [[parts objectAtIndex:index + 3] floatValue];
        float rotation = [[parts objectAtIndex:index + 4] floatValue];

        // offset the shadows into the woods to be inside the margin
        x += woodsMargin;
        y += woodsMargin;

        CCSprite * shadow = shadows[ treeId ];
        shadow.position = ccp( x - min_x + shadowOffsetX, y - min_y + shadowOffsetY );

        // scale and rotate a bit randomly
        shadow.scale = scale;
        shadow.rotation = rotation;

        // render into the texture
        [shadow visit];

        created++;
    }

    // the data is: id x y scale rotation
    for ( unsigned int index = 1; index < parts.count; index += 5 ) {
        int treeId     = [[parts objectAtIndex:index + 0] intValue];
        float x        = [[parts objectAtIndex:index + 1] floatValue];
        float y        = [[parts objectAtIndex:index + 2] floatValue];
        float scale    = [[parts objectAtIndex:index + 3] floatValue];
        float rotation = [[parts objectAtIndex:index + 4] floatValue];

        // offset the tree into the woods to be inside the margin
        x += woodsMargin;
        y += woodsMargin;

        CCSprite * tree = trees[ treeId ];
        tree.position = ccp( x - min_x, y - min_y );
        
        // scale and rotate a bit randomly
        tree.scale = scale;
        tree.rotation = rotation;

        // render into the texture
        [tree visit];
    }

    // use the render texture's result sprite
    [renderTexture end];

    self.anchorPoint = ccp( 0, 0 );
    
    // position it at the min coordinates, as the texture is only as big as it needs to be to contain the
    // whole polygon
    renderTexture.position = ccp( min_x - woodsMargin, min_y - woodsMargin );

    // the anchor point is fubar. without this the texture is positioned off to the left and down, no idea why...
    renderTexture.anchorPoint = ccp( 0, 0 );
    renderTexture.sprite.anchorPoint = ccp( 0, 1 );

    // add the sprites directly onto the map
    [[Globals sharedInstance].mapLayer addChild:renderTexture z:self.mapLayerZ];
    //[self addChild:renderTexture];
}


@end
