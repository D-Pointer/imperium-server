
#import "TutorialPart.h"

@interface TutorialMoveUnit : TutorialPart

- (id) initWithUnitId:(int)unitId toPos:(CGPoint)pos radius:(float)radius;

- (id) initWithUnitId:(int)unitId toPos:(CGPoint)pos radius:(float)radius orEnemySeen:(BOOL)seen;

@end
