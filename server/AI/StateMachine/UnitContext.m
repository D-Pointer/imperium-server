
#import "UnitContext.h"
#import "Idle.h"

@implementation UnitContext

- (instancetype)initWithUnit:(Unit *)unit {
    self = [super init];
    if (self) {
        self.unit = unit;
        self.currentState = [Idle new];

        CCLOG( @"creating for %@", unit );
    }

    return self;
}

@end
