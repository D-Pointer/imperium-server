
#import "ShouldTakeObjective.h"
#import "Organization.h"

@implementation ShouldTakeObjective

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ OrgShouldTakeObjective ] = @(context.unit.organization.order == kTakeObjective);
}

@end
