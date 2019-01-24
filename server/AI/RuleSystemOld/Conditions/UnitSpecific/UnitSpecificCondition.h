
#import "Action.h"
#import "Unit.h"

@interface UnitSpecificCondition : Action

@property (nonatomic, weak) Unit * unit;

- (instancetype) initWithUnit:(Unit *)unit;

@end
