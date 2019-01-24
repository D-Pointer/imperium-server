
#import "BeginningOfGame.h"
#import "Clock.h"

@implementation BeginningOfGame

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    // beginning is the first 5 minutes
    if ( [Globals sharedInstance].clock.elapsedTime < 300 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
