
#import "AreAllObjectivesHeld.h"
#import "Objective.h"
#import "Globals.h"

@implementation AreAllObjectivesHeld

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    // check all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( objective.state != kOwnerPlayer2 ) {
            // this objective is held by the other player or contested
            return kFailed;
        }
    }

    // we hold all objectives
    return kSucceeded;
}

@end
