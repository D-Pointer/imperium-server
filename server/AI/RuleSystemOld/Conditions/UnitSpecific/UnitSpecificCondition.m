
#import "UnitSpecificCondition.h"

@implementation UnitSpecificCondition

- (instancetype) initWithUnit:(Unit *)unit {
    self = [super init];
    if (self) {
        self.unit = unit;
    }

    return self;
}

@end
