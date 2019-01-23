
#import <GameplayKit/GameplayKit.h>
#import "Definitions.h"

@class Unit;

@interface UnitContext : NSObject

@property (nonatomic, weak) Unit * unit;

//@property (nonatomic, weak) Unit * closestEnemyInRange;
//@property (nonatomic, weak) Unit * closestEnemyInFieldOfFire;
//@property (nonatomic, weak) Unit * closestRallyableUnit;
//
//@property (nonatomic, strong) NSMutableSet * enemiesInRange;
//@property (nonatomic, strong) NSMutableSet * enemiesInFieldOfFire;
//@property (nonatomic, strong) NSMutableSet * rallyableUnits;

- (void) clear;

@end
