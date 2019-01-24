
#import "ShouldHold.h"
#import "Organization.h"

@implementation ShouldHold

- (void) update {
    self.isTrue = self.organization.order == kHold;
}

@end
