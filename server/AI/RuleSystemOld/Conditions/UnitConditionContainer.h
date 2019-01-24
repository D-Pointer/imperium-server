
#import "Globals.h"

#import "HasEnemiesInFieldOfFire.h"
#import "HasMission.h"
#import "HasTarget.h"
#import "HasEnemiesInRange.h"
#import "IsColumnMode.h"
#import "IsFormationMode.h"
#import "IsSupportUnit.h"
#import "IsUnderFire.h"
#import "IsFullStrength.h"
#import "IsHalfStrength.h"
#import "IsLowStrength.h"
#import "SeesEnemies.h"
#import "HasAmmo.h"
#import "CanAssault.h"
#import "Morale.h"
#import "CanRally.h"
#import "IsIndirectFireUnit.h"
#import "HasHq.h"
#import "IsHq.h"

@interface UnitConditionContainer : NSObject

// the unit we operate on
@property (nonatomic, weak)   Unit *          unit;

// unit specific conditions
@property (nonatomic, strong) CanAssault *              canAssault;
@property (nonatomic, strong) CanRally *                canRally;
@property (nonatomic, strong) HasEnemiesInFieldOfFire * hasEnemiesInFieldOfFire;
@property (nonatomic, strong) HasEnemiesInRange *       hasEnemiesInRange;
@property (nonatomic, strong) SeesEnemies *             seesEnemies;
@property (nonatomic, strong) HasMission *              hasMission;
@property (nonatomic, strong) HasAmmo *                 hasAmmo;
@property (nonatomic, strong) HasHq *                   hasHq;
@property (nonatomic, strong) HasTarget *               hasTarget;
@property (nonatomic, strong) IsColumnMode *            isColumnMode;
@property (nonatomic, strong) IsFormationMode *         isFormationMode;
@property (nonatomic, strong) IsHq *                    isHq;
@property (nonatomic, strong) IsSupportUnit *           isSupportUnit;
@property (nonatomic, strong) IsUnderFire *             isUnderFire;
@property (nonatomic, strong) IsFullStrength *          isFullStrength;
@property (nonatomic, strong) IsHalfStrength *          isHalfStrength;
@property (nonatomic, strong) IsLowStrength *           isLowStrength;
@property (nonatomic, strong) IsIndirectFireUnit *      isIndirectFireUnit;
@property (nonatomic, strong) Morale *                  morale;

- (instancetype) initWithUnit:(Unit *)unit;

/**
 * Updates the conditions.
 **/
- (void) update;

@end
