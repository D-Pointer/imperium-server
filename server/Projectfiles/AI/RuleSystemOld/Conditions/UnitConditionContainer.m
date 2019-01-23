
#import "UnitConditionContainer.h"

@interface UnitConditionContainer ()

@property (nonatomic, strong) NSArray * unitConditions;

@end

@implementation UnitConditionContainer

- (instancetype) initWithUnit:(Unit *)unit {
    self = [super init];
    if (self) {
        self.unit = unit;

        self.canAssault               = [[CanAssault alloc] initWithUnit:unit];
        self.canRally                 = [[CanRally alloc] initWithUnit:unit];
        self.hasEnemiesInFieldOfFire  = [[HasEnemiesInFieldOfFire alloc] initWithUnit:unit];
        self.hasEnemiesInRange        = [[HasEnemiesInRange alloc] initWithUnit:unit];
        self.hasMission               = [[HasMission alloc] initWithUnit:unit];
        self.hasAmmo                  = [[HasAmmo alloc] initWithUnit:unit];
        self.hasHq                    = [[HasHq alloc] initWithUnit:unit];
        self.hasTarget                = [[HasTarget alloc] initWithUnit:unit];
        self.isColumnMode             = [[IsColumnMode alloc] initWithUnit:unit];
        self.isFormationMode          = [[IsFormationMode alloc] initWithUnit:unit];
        self.isHq                     = [[IsHq alloc] initWithUnit:unit];
        self.isIndirectFireUnit       = [[IsIndirectFireUnit alloc] initWithUnit:unit];
        self.isSupportUnit            = [[IsSupportUnit alloc] initWithUnit:unit];
        self.isUnderFire              = [[IsUnderFire alloc] initWithUnit:unit];
        self.isFullStrength           = [[IsFullStrength alloc] initWithUnit:unit];
        self.isHalfStrength           = [[IsHalfStrength alloc] initWithUnit:unit];
        self.isLowStrength            = [[IsLowStrength alloc] initWithUnit:unit];
        self.seesEnemies              = [[SeesEnemies alloc] initWithUnit:unit];
        self.morale                   = [[Morale alloc] initWithUnit:unit];

        // a convenient list of all conditions
        self.unitConditions = @[ self.canAssault,
                                 self.canRally,
                                 self.hasEnemiesInFieldOfFire,
                                 self.hasEnemiesInRange,
                                 self.hasMission,
                                 self.hasAmmo,
                                 self.hasHq,
                                 self.hasTarget,
                                 self.isColumnMode,
                                 self.isFormationMode,
                                 self.isHq,
                                 self.isIndirectFireUnit,
                                 self.isSupportUnit,
                                 self.isUnderFire,
                                 self.isFullStrength,
                                 self.isHalfStrength,
                                 self.isLowStrength,
                                 self.seesEnemies,
                                 self.morale
                                 ];

        CCLOG( @"set up %lu unit specific conditions for %@", (unsigned long)self.unitConditions.count, unit );
    }

    return self;
}


- (void) update {
    //CCLOG( @"updating conditions for unit %@", self.unit );

    for ( UnitSpecificCondition * condition in self.unitConditions ) {
        [condition update];
        CCLOG( @"unit %@, condition %@ == %@", self.unit, condition.name, condition.isTrue ? @"yes" : @"no" );
    }
}

@end
