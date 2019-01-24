
#import "IsHeadquarterAlive.h"
#import "Organization.h"

@implementation IsHeadquarterAlive

- (void) update {
    self.isTrue = self.organization.headquarter && self.organization.headquarter.destroyed == NO;
}

@end
