
#import "AreAllObjectivesHeld.h"
#import "Objective.h"
#import "Globals.h"

@implementation AreAllObjectivesHeld

- (void) update:(UnitContext *)context {
    // check all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( objective.state != kOwnerPlayer2 ) {
            // this objective is held by the other player or contested
            context.ruleSystem.state[ GlobAllObjectivesHeld ] = @NO;
            return;
        }
    }

    // we hold all objectives
    context.ruleSystem.state[ GlobAllObjectivesHeld ] = @YES;
}

@end
