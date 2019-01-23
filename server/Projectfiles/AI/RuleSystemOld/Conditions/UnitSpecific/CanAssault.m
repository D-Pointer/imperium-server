
#import "CanAssault.h"
#import "Scenario.h"

@implementation CanAssault

- (void) update {
    self.isTrue = self.unit.assaultSpeed > 0 && self.unit.mode == kFormation && [self.unit isIdle] && [self.unit canBeGivenMissions];
}

@end
