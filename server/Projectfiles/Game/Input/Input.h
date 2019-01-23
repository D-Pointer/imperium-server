
#import "cocos2d.h"
#import "Unit.h"
#import "Objective.h"

@interface Input : NSObject

- (void) handleClickedUnit:(Unit *)clicked;

- (void) handleClickedObjective:(Objective *)objective;

- (void) handleClickedPos:(CGPoint)pos;

- (void) handleDragStartForUnit:(Unit *)unit;

- (BOOL) handleDragForUnit:(Unit *)unit toPos:(CGPoint)pos;

- (void) handleDragEndForUnit:(Unit *)unit;

@end
