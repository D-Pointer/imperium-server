
#import "AreAllObjectivesHeld.h"
#import "Objective.h"
#import "Globals.h"
#import "UnitContext.h"

@implementation AreAllObjectivesHeld

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    // check all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( objective.state != kOwnerPlayer2 ) {
            // this objective is held by the other player or contested
            context.areAllObjectivesHeld = NO;
        }
    }

    // we hold all objectives
    context.areAllObjectivesHeld = YES;
}


@end
