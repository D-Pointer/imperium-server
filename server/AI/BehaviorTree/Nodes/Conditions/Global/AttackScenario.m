
#import "AttackScenario.h"
#import "Scenario.h"

@implementation AttackScenario

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( [Globals sharedInstance].scenario.aiHint == kPlayer2Attacks ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
