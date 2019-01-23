
#import "IsIndirectFireUnit.h"
#import "Scenario.h"

@implementation IsIndirectFireUnit

- (void) update {
    self.isTrue = self.unit.weapon.type == kMortar || self.unit.weapon.type == kHowitzer;
}

@end
