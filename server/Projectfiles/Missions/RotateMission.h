
#import "Mission.h"

@interface RotateMission : Mission

@property (nonatomic, assign) CGPoint target;

- (id) initFacingTarget:(CGPoint)pos;
- (id) initFacingTarget:(CGPoint)pos maxDeviation:(float)deviation;


@end
