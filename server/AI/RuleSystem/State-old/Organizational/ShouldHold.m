
#import "ShouldHold.h"
#import "Organization.h"

@implementation ShouldHold

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ OrgShouldHold ] = @(context.unit.organization.order == kHold);
}

@end
