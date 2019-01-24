
#import "OrganizationSpecificCondition.h"

@implementation OrganizationSpecificCondition

- (instancetype) initWithOrganization:(Organization *)organization {
    self = [super init];
    if (self) {
        self.organization = organization;
    }

    return self;
}


@end
