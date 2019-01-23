
#import "HasAmmo.h"
#import "CombatMission.h"

@implementation HasAmmo

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.weapon.ammo > 0 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
