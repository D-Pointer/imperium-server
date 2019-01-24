
#import "AreAllObjectivesHeld.h"
#import "Objective.h"
#import "Globals.h"

@implementation AreAllObjectivesHeld

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    // check all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( objective.state != kOwnerPlayer2 ) {
            // this objective is held by the other player or contested
            [system assertFact:FactAttack grade:0.2f];
            return NO;
        }
    }

    // we hold all objectives
    return YES;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system retractFact:FactAttack grade:0.4f];
    [system assertFact:FactHold grade:0.4f];
}

@end
