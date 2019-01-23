
#import "cocos2d.h"
#import "StrategicPlanner.h"
#import "Organization.h"
#import "RuleSystem.h"

@interface TacticalPlanner : NSObject

@property (nonatomic, strong) StrategicPlanner * strategicPlanner;
@property (nonatomic, weak)   RuleSystem *       ruleSystem;

- (void) performTacticalPlanning;

- (void) planForOrganization:(Organization *)organization;

- (void) planForIndependent:(Unit *)unit;

@end
