
#import "IsHq.h"
#import "Scenario.h"

@implementation IsHq

- (void) update {
    self.isTrue = self.unit.type == kInfantryHeadquarter || self.unit.type == kCavalryHeadquarter;
}

@end
