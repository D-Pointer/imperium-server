
#import "ShouldAdvance.h"
#import "Organization.h"

@implementation ShouldAdvance

- (void) update {
    self.isTrue = self.organization.order == kAdvanceTowardsEnemy;
}

@end
