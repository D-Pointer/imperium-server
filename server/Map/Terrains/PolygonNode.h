

#import "Definitions.h"

@interface PolygonNode : NSObject {
    // data for the triangles. vertices are repeated as needed
	CGPoint * vertices_;

    // original vertices in the order they were given
    CGPoint * originalVertices_;
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

- (id) initWithPolygon:(NSMutableArray *)vertices terrainType:(TerrainType)type smoothing:(BOOL)smoothing;

- (BOOL) containsPoint:(CGPoint)point;

- (BOOL) intersectsLineFrom:(CGPoint)start to:(CGPoint)end atPos:(float *)pos;

- (void) addAllIntersectionsFrom:(CGPoint)start to:(CGPoint)end into:(NSMutableArray *)result;

@end
