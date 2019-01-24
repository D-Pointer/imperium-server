
#import "IsSupportUnit.h"
#import "Scenario.h"

@implementation IsSupportUnit

- (void) update {
    self.isTrue = self.unit.type == kArtillery || self.unit.weapon.type == kMachineGun || self.unit.weapon.type == kMortar;
}

@end
