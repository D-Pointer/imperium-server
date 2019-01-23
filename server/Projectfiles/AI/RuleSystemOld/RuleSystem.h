
#import "Globals.h"
#import "Rule.h"

@class Organization;
@class GlobalConditionContainer;

@interface RuleSystem : NSObject

// global and unit specific conditions
@property (nonatomic, strong) GlobalConditionContainer * globalConditions;
@property (nonatomic, strong) NSMutableDictionary *      unitConditions;

// all rules
@property (nonatomic, strong) NSArray *                  rules;


/**
 * Updates all the conditions
 **/
- (void) updateGlobalConditions;

- (void) updateOrganizationalConditions:(CCArray *)organizations;

- (UnitConditionContainer *) updateConditionsForUnit:(Unit *)unit;

@end
