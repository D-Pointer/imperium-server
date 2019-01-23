
#import "DefendScenario.h"
#import "Scenario.h"

@implementation DefendScenario

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( [Globals sharedInstance].scenario.aiHint == kPlayer1Attacks ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
