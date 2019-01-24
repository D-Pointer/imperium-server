
#import "Definitions.h"

@class Unit;
@class State;

@interface UnitContext : NSObject

@property (nonatomic, weak) Unit * unit;

@property (nonatomic, strong) State * currentState;

// global info
@property (nonatomic, assign) BOOL areAllObjectivesHeld;
@property (nonatomic, assign) BOOL isAttackScenario;
@property (nonatomic, assign) BOOL isBeginningOfGame;
@property (nonatomic, assign) BOOL isDefendScenario;
@property (nonatomic, assign) BOOL isFirstTurn;
@property (nonatomic, assign) BOOL isMeetingScenario;

// organizational info
@property (nonatomic, assign) BOOL isHeadquarterAlive;
@property (nonatomic, assign) BOOL shouldAdvance;
@property (nonatomic, assign) BOOL shouldHold;
@property (nonatomic, assign) BOOL shouldTakeObjective;

// unit specific info
@property (nonatomic, strong) NSArray * enemiesInRange;
@property (nonatomic, strong) NSArray * enemiesInFieldOfFire;
@property (nonatomic, weak)   Unit *    closestEnemyInRange;
@property (nonatomic, weak)   Unit *    closestEnemyInFieldOfFire;

@property (nonatomic, strong) NSArray * rallyableUnits;
@property (nonatomic, weak)   Unit *    closestRallyableUnit;

//@property (nonatomic, weak) Unit * closestEnemyInRange;
//@property (nonatomic, weak) Unit * closestEnemyInFieldOfFire;
//@property (nonatomic, weak) Unit * closestRallyableUnit;
//
//@property (nonatomic, strong) NSMutableSet * enemiesInRange;
//@property (nonatomic, strong) NSMutableSet * enemiesInFieldOfFire;
//@property (nonatomic, strong) NSMutableSet * rallyableUnits;

- (instancetype)initWithUnit:(Unit *)unit;

@end
