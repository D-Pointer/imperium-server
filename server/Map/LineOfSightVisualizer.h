
#import "cocos2d.h"

@interface LineOfSightVisualizer : CCNode

/**
 * Visualizes an unblocked LOS from start to end.
 **/
- (void) showFrom:(CGPoint)start to:(CGPoint)end;

/**
 * Visualizes a blocked LOS which is ok from start to middle and then blocked from middle to end.
 **/
- (void) showFrom:(CGPoint)start toMiddle:(CGPoint)middle withEnd:(CGPoint)end;

@end
