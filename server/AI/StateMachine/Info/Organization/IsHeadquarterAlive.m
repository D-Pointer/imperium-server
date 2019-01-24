
#import "IsHeadquarterAlive.h"
#import "Organization.h"
#import "UnitContext.h"

@implementation IsHeadquarterAlive

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    Unit * unit = context.unit;
    context.isHeadquarterAlive = unit.organization.headquarter && unit.organization.headquarter.destroyed == NO;
}


@end
