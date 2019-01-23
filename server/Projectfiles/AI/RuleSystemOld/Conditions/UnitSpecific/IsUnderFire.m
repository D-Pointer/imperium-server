
#import "IsUnderFire.h"
#import "CombatMission.h"

@implementation IsUnderFire

- (void) update {
    int firing = 0;

    // check all enemies
    for ( Unit * enemy in [Globals sharedInstance].unitsPlayer1 ) {
        if ( enemy.mission && [enemy.mission isKindOfClass:[CombatMission class]] && ((CombatMission *)enemy.mission).targetUnit == self.unit ) {
            // the unit is being targeted by this enemy
            firing++;
        }
    }

    self.value = [NSNumber numberWithInt:firing];
    self.isTrue = firing > 0;
}

@end
