
#import "ShouldHold.h"
#import "Organization.h"
#import "UnitContext.h"

@implementation ShouldHold

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    Unit * unit = context.unit;
    context.shouldHold = unit.organization.order == kHold;
}

@end
