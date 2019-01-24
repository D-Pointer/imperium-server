
#import "InfluenceMapNode.h"
#import "Globals.h"

@implementation InfluenceMapNode

- (id) initWithMap:(MapBase *)influenceMap {
    self = [InfluenceMapNode spriteWithTexture:influenceMap.texture];
    if (self) {
        _influenceMap = influenceMap;
    }

    return self;
}


//- (void) touchEnded: (CGPoint)position {
//    NSLog( @"InfluenceMapDialog.touchEnded" );
//    
////    if ( self.parent ) {
////        NSLog( @"InfluenceMapDialog.touchEnded: removing" );
////        [self removeFromParentAndCleanup:YES];
////    }
//}


- (void) update {
    [self setTexture:self.influenceMap.texture];
}


//- (void) updateLayer {
//    if ( self.layer ) {
//        [self.layer removeFromParentAndCleanup:YES];
//    }

    // create a new layer from the map
//    MapBaseLayer * map_layer = [MapBaseLayer createFromMap:self.map];
//    
//    self.layer = map_layer;
//    self.layer.position = ccp( [self.layer boundingBox].size.width * -0.5, [self.layer boundingBox].size.height * -0.5 );
//    [self addChild:self.layer];    
//    
//    CCLabelBMFont * label = [Dialog createGlyphLabel:self.map.title glyphDefinition:MessageFont position:ccp( 0, 0 )];
//    label.anchorPoint = ccp( 0.5, 1.0f );
//    label.position = ccp( 0, [self.layer boundingBox].size.height * 0.5 );
//    [self addChild: label];
//}


//+ (InfluenceMapNode *) showMap:(MapBase *)map {
//    CGSize size = [[CCDirector sharedDirector] winSize];
//
//    // create the dialog
//    InfluenceMapNode * dialog = [[InfluenceMapNode alloc] initWithMap:map];
//    dialog.position = CGPointMake( size.width * 0.5, size.height * 0.5);
//
//    return dialog;
//}


@end
