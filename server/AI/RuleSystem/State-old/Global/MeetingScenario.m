
#import "MeetingScenario.h"
#import "Scenario.h"
#import "Globals.h"

@implementation MeetingScenario

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ GlobIsMeetingScenario ] = @( [Globals sharedInstance].scenario.aiHint == kMeetingEngagement );
}

@end
