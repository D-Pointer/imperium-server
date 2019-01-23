
#import "IsHeadquarterAlive.h"
#import "Organization.h"

@implementation IsHeadquarterAlive

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ OrgIsHqAlive ] = @(context.unit.organization.headquarter && context.unit.organization.headquarter.destroyed == NO);
}

@end
