
#import "ShouldTakeObjective.h"
#import "Organization.h"

@implementation ShouldTakeObjective

- (void) update {
    self.isTrue = self.organization.order == kTakeObjective;
}

@end
