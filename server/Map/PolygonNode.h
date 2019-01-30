
#import <CoreGraphics/CoreGraphics.h>

#import "Definitions.h"

@interface PolygonNode : NSObject {
    // original vertices in the order they were given
    CGPoint * vertices_;

    // how many vertices
    NSUInteger vertexCount;

    // bounding box helpers
    CGFloat min_x;
    CGFloat min_y;
    CGFloat max_x;
    CGFloat max_y;
}


@property (assign, nonatomic) TerrainType terrainType;
@property (assign, nonatomic) CGPoint     position;
@property (assign, nonatomic) CGRect      boundingBox;

- (id) initWithPolygon:(NSMutableArray *)vertices terrainType:(TerrainType)type;

- (BOOL) containsPoint:(CGPoint)point;

- (BOOL) intersectsLineFrom:(CGPoint)start to:(CGPoint)end atPos:(float *)pos;

- (void) addAllIntersectionsFrom:(CGPoint)start to:(CGPoint)end into:(NSMutableArray *)result;

@end
