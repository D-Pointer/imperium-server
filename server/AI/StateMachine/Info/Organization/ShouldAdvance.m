
#import "ShouldAdvance.h"
#import "Organization.h"
#import "UnitContext.h"

@implementation ShouldAdvance

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    Unit * unit = context.unit;
    context.shouldAdvance = unit.organization.order == kAdvanceTowardsEnemy;
}

@end
