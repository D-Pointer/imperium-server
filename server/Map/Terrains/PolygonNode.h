

#import "Definitions.h"

@interface PolygonNode : CCNode {
    // data for the triangles. vertices are repeated as needed
	ccVertex2F * vertices_;

    // original vertices in the order they were given
    ccVertex2F * originalVertices_;
    NSUInteger original_count;

    // how many vertices
    NSUInteger vertex_count;

    // bounding box helpers
    CGFloat min_x;
    CGFloat min_y;
    CGFloat max_x;
    CGFloat max_y;

    CGRect boundingBox_;
}


@property (assign, nonatomic) TerrainType terrainType;
@property (assign, nonatomic) MapLayerZ   mapZ;

- (id) initWithPolygon:( NSMutableArray *)vertices smoothing:(BOOL)smoothing;

- (id) initWithPolygon:( NSMutableArray *)vertices;

- (void) setupShaders;

//- (void) bindTextures;

- (BOOL) containsPoint:(CGPoint)point;

- (BOOL) intersectsLineFrom:(CGPoint)start to:(CGPoint)end atPos:(float *)pos;

- (void) addAllIntersectionsFrom:(CGPoint)start to:(CGPoint)end into:(NSMutableArray *)result;

@end
