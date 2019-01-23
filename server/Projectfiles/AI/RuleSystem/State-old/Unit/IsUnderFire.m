
#import "IsUnderFire.h"
#import "CombatMission.h"

@implementation IsUnderFire

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    int firing = 0;

    Unit * unit = context.unit;

    // check all enemies
    for ( Unit * enemy in [Globals sharedInstance].unitsPlayer1 ) {
        if ( enemy.mission && [enemy.mission isKindOfClass:[CombatMission class]] && ((CombatMission *)enemy.mission).targetUnit == unit ) {
            // the unit is being targeted by this enemy
            firing++;
        }
    }

    if ( firing > 0 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
