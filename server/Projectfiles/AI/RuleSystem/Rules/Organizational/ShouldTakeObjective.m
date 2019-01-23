
#import "ShouldTakeObjective.h"
#import "Organization.h"

@implementation ShouldTakeObjective

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    Unit * unit = system.state[ @"unit" ];
    return unit.organization.order == kTakeObjective;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactOrgTakeObjective grade:0.6f];
    [system assertFact:FactOrgAttack grade:0.4f];
    [system retractFact:FactOrgHold grade:0.4f];
}

@end
