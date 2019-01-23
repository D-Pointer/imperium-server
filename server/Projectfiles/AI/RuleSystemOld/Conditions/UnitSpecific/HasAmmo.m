
#import "HasAmmo.h"
#import "CombatMission.h"

@implementation HasAmmo

- (void) update {
    self.isTrue = self.unit.weapon.ammo > 0;
    self.value = [NSNumber numberWithInt:self.unit.weapon.ammo];
}

@end
