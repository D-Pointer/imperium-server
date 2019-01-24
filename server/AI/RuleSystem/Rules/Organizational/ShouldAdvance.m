
#import "ShouldAdvance.h"
#import "Organization.h"

@implementation ShouldAdvance

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    Unit * unit = system.state[ @"unit" ];
    return unit.organization.order == kAdvanceTowardsEnemy;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactOrgTakeObjective grade:0.2f];
    [system assertFact:FactOrgAttack grade:0.6f];
    [system retractFact:FactOrgHold grade:0.3f];
}

@end
