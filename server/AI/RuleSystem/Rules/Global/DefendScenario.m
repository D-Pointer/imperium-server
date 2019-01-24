
#import "DefendScenario.h"
#import "Scenario.h"
#import "Globals.h"

@implementation DefendScenario

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    return [Globals sharedInstance].scenario.aiHint == kPlayer1Attacks;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system retractFact:FactAttack grade:0.2f];
    [system assertFact:FactHold grade:0.6f];
}


@end
