
#import "AttackScenario.h"
#import "Globals.h"
#import "Scenario.h"

@implementation AttackScenario

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    return [Globals sharedInstance].scenario.aiHint == kPlayer2Attacks;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactAttack grade:0.6f];
    [system retractFact:FactHold grade:0.2f];
}

@end
