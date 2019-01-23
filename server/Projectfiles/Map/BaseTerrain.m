
#import "BaseTerrain.h"


@implementation BaseTerrain


- (BOOL) containsPoint:(CGPoint)point {
    // not interactive in any way
    return NO;
}


- (BOOL) intersectsLineFrom:(CGPoint)start to:(CGPoint)end atPos:(float *)pos {
    // nothing intersects this polygon
    return NO;
}


@end
