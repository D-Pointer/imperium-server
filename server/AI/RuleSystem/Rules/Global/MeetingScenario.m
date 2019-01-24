
#import "MeetingScenario.h"
#import "Scenario.h"
#import "Globals.h"

@implementation MeetingScenario

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    return [Globals sharedInstance].scenario.aiHint == kMeetingEngagement;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactAttack grade:0.4f];
    [system assertFact:FactHold grade:0.2f];
}

@end
