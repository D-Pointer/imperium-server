
#import <GameKit/GameKit.h>
#import "Definitions.h"

@class TacticalPlanner;
@class Organization;
@class Objective;
@class PotentialField;

@interface StrategicPlanner : NSObject

@property (nonatomic, assign) AIAggressiveness aggressiveness;

// all rule system state created by executing the planner. Should be used for all units
@property (nonatomic, strong) NSMutableDictionary * ruleSystemState;

@property (nonatomic, strong) CCArray * ownUnits;
@property (nonatomic, strong) CCArray * enemyUnits;
@property (nonatomic, strong) CCArray * ownOrganizations;
@property (nonatomic, strong) CCArray * enemyGroups;
@property (nonatomic, strong) CCArray * targetObjectives;
@property (nonatomic, assign) PlayerId  aiPlayer;

- (void) executeWithPotentialField:(PotentialField *)field;

// private
- (void) performStrategicPlanning;

- (Organization *) findClosestOrganizationTo:(Objective *)objective;

@end
