#import "Definitions.h"
#import "Unit.h"
#import "PotentialField.h"
#import "Blackboard.h"


@interface BehaviorTreeContext : NSObject

// the unit the tree now operates on
@property (nonatomic, weak) Unit *unit;

// total elapsed time in simulation seconds
@property (nonatomic, assign) float elapsedTime;

@property (nonatomic, weak) PotentialField * potentialField;

// blackboard where nodes can write changing data
@property (nonatomic, strong) Blackboard *blackboard;

@end