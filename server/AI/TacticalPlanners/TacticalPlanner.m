
#import "TacticalPlanner.h"
#import "Globals.h"

@implementation TacticalPlanner

- (id) init {
    self = [super init];
    if (self) {
        // nothing to do
    }

    return self;
}


- (void) performTacticalPlanning {
    Rule * chosenRule = nil;

    // match rules for all our units
    for ( Unit * unit in [Globals sharedInstance].unitsPlayer2 ) {
        // only handle alive units
        if ( unit.destroyed ) {
            continue;
        }

        Organization * organization = nil;

        // find the organization
        for ( Organization * tmp in self.strategicPlanner.organizations ) {
            if ( [tmp containsUnit:unit] ) {
                organization = tmp;
                break;
            }
        }

        NSAssert( organization != nil, @"no organization found for unit %@", unit );

        // get the organization and unit specific condition containers
        OrganizationConditionContainer * organizationConditions = organization.conditions;
        UnitConditionContainer * unitConditions = self.ruleSystem.unitConditions[ [NSNumber numberWithInt:unit.unitId] ];
        NSAssert( unitConditions != nil, @"no unit conditions found for unit %@", unit );

        // check all rules that match for this unit
        for ( Rule * rule in self.ruleSystem.rules ) {
            if ( [rule checkMatchForUnit:unit withGlobalConditions:self.ruleSystem.globalConditions withOrganizationConditions:organizationConditions withUnitConditions:unitConditions] ) {
                // new highest priority rule?
                if ( chosenRule == nil || chosenRule.priority < rule.priority ) {
                    chosenRule = rule;
                }
            }
        }

        if ( chosenRule != nil ) {
            CCLOG( @"executing chosen rule: %@, priority: %d", chosenRule.name, chosenRule.priority );
            [chosenRule executeForUnit:unit inOrganization:organization];
        }
        else {
            CCLOG( @"no rule matches for unit %@", unit );
        }
    }
}


- (void) planForOrganization:(Organization *)organization {
    NSAssert( NO, @"Must be overridden" );
}


- (void) planForIndependent:(Unit *)unit {
    NSAssert( NO, @"Must be overridden" );
}


@end
