
#import "IsHeadquarterAlive.h"
#import "Organization.h"

@implementation IsHeadquarterAlive

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    Unit * unit = system.state[ @"unit" ];
    return unit.organization.headquarter && unit.organization.headquarter.destroyed == NO;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactOrgTakeObjective grade:0.1f];
    [system assertFact:FactOrgAttack grade:0.1f];
    [system retractFact:FactOrgHold grade:0.1f];
}


@end
