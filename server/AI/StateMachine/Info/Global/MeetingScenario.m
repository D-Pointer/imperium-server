
#import "MeetingScenario.h"
#import "Scenario.h"
#import "Globals.h"
#import "UnitContext.h"

@implementation MeetingScenario

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = -1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    context.isMeetingScenario = [Globals sharedInstance].scenario.aiHint == kMeetingEngagement;
}

@end
