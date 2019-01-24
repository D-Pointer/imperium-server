
#import "ShouldTakeObjective.h"
#import "Organization.h"
#import "UnitContext.h"

@implementation ShouldTakeObjective

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    Unit * unit = context.unit;
    context.shouldTakeObjective = unit.organization.order == kTakeObjective;
}


@end
