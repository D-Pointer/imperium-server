
#import "MeetingScenario.h"
#import "Scenario.h"

@implementation MeetingScenario

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( [Globals sharedInstance].scenario.aiHint == kMeetingEngagement ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
