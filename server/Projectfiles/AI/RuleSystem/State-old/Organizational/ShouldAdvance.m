
#import "ShouldAdvance.h"
#import "Organization.h"

@implementation ShouldAdvance

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ OrgShouldAdvance ] = @(context.unit.organization.order == kAdvanceTowardsEnemy);
}

@end
