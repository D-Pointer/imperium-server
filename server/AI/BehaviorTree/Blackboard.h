
#import "Definitions.h"

@class Unit;
@class ActionNode;

@interface Blackboard : NSObject

@property (nonatomic, weak) Unit * closestEnemyInRange;
@property (nonatomic, weak) Unit * closestEnemyInFieldOfFire;
@property (nonatomic, weak) Unit * closestRallyableUnit;

@property (nonatomic, strong) NSMutableSet * enemiesInRange;
@property (nonatomic, strong) NSMutableSet * enemiesInFieldOfFire;
@property (nonatomic, strong) NSMutableSet * rallyableUnits;

@property (nonatomic, weak) ActionNode * executedAction;

@property (nonatomic, strong) NSMutableArray * trace;

// space for node specific data, indexed by unit id and the data is something the node only knows
@property (nonatomic, strong) NSMutableDictionary * nodeData;

- (void) clear;

@end
