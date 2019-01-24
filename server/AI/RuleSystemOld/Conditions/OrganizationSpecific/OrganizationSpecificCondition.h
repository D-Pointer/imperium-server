
#import "Action.h"

@class Organization;

@interface OrganizationSpecificCondition : Action

@property (nonatomic, weak) Organization * organization;

- (instancetype) initWithOrganization:(Organization *)organization;

@end
