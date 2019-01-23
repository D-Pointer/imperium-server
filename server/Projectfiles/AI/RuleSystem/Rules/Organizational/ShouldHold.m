
#import "ShouldHold.h"
#import "Organization.h"

@implementation ShouldHold

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    Unit * unit = system.state[ @"unit" ];
    return unit.organization.order == kHold;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system retractFact:FactOrgTakeObjective grade:0.6f];
    [system retractFact:FactOrgAttack grade:0.6f];
    [system assertFact:FactOrgHold grade:0.6f];
}

@end
