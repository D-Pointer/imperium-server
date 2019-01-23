#import "Weapon.h"
#import "Globals.h"

@interface Weapon ()

@property (nonatomic, readwrite, assign) WeaponType type;

@end


@implementation Weapon

- (id) initWithType:(WeaponType)type {
    self = [super init];
    if (self) {
        self.type = type;
    }

    return self;
}


- (NSString *) name {
    switch (self.type) {
        case kRifle:
            return @"Rifle";

        case kRifleMk2:
            return @"Rifle MK2";

        case kSubmachineGun:
            return @"Submachine gun";

        case kMachineGun:
            return @"Machinegun";

        case kLightCannon:
            return @"Light Cannon";

        case kHeavyCannon:
            return @"Heavy Cannon";

        case kFlamethrower:
            return @"Flamethrower";

        case kMortar:
            return @"Mortar";

        case kHowitzer:
            return @"Howitzer";

        case kSniperRifle:
            return @"Sniper rifle";
    }
}


- (float) firepower {
    // in damage for one unit

    switch (self.type) {
        case kRifle:
            return 0.3;

        case kRifleMk2:
            return 0.4;

        case kSniperRifle:
            return 0.7;

        case kSubmachineGun:
            return 0.6;

        case kMachineGun:
            return 3;

        case kLightCannon:
            return 6;

        case kHeavyCannon:
            return 9;

        case kMortar:
            return 6;

        case kHowitzer:
            return 10;

        case kFlamethrower:
            return 8;

    }
}


- (float) firingRange {
    // in meters

    switch (self.type) {
        case kRifle:
            return 250;


        case kRifleMk2:
            return 300;

        case kSniperRifle:
            return 500;

        case kSubmachineGun:
            return 150;


        case kMachineGun:
            return 400;


        case kLightCannon:
            return 550;


        case kHeavyCannon:
            return 700;


        case kMortar:
            return 400;


        case kHowitzer:
            return 600;


        case kFlamethrower:
            // too short?
            return 100;

    }
}


- (float) firingAngle {
    // in degrees

    switch (self.type) {
        case kRifle:
        case kRifleMk2:
        case kSubmachineGun:
        case kSniperRifle:
            return 100;


        case kMachineGun:
            return 60;


        case kLightCannon:
            return 40;


        case kHeavyCannon:
            return 30;


        case kMortar:
            return 50;


        case kHowitzer:
            return 30;


        case kFlamethrower:
            return 40;

    }
}


- (float) reloadingTime {
    // in seconds

    // hardcoded fast time for tutorial
    if ([Globals sharedInstance].tutorial) {
        return 10;
    }

    // if the weapon has no ammo then the reloading time is much longer. the troops will then share
    // what ammo they have and scavenge it from somewhere
    float ammoModifier = self.ammo <= 0 ? 2.0f : 1.0f;

    switch (self.type) {
        case kRifle:
            return (25 + CCRANDOM_0_1() * 10) * ammoModifier;

        case kRifleMk2:
            return (20 + CCRANDOM_0_1() * 10) * ammoModifier;

        case kSniperRifle:
            return (25 + CCRANDOM_0_1() * 10) * ammoModifier;

        case kSubmachineGun:
            return (25 + CCRANDOM_0_1() * 5) * ammoModifier;

        case kMachineGun:
            return (12 + CCRANDOM_0_1() * 5) * ammoModifier;

        case kLightCannon:
            return (40 + CCRANDOM_0_1() * 20) * ammoModifier;

        case kHeavyCannon:
            return (50 + CCRANDOM_0_1() * 20) * ammoModifier;

        case kMortar:
            return (20 + CCRANDOM_0_1() * 10) * ammoModifier;

        case kHowitzer:
            return (50 + CCRANDOM_0_1() * 20) * ammoModifier;

        case kFlamethrower:
            return (15 + CCRANDOM_0_1() * 10) * ammoModifier;

    }
}


- (void) setAmmo:(int)ammo {
    // make sure it stays positive
    _ammo = ammo < 0 ? 0 : ammo;
}


- (SoundType) firingSound {
    switch (self.type) {
        case kRifle:
        case kRifleMk2:
            return kInfantryFiring;

        case kSniperRifle:
            return kSniperFiring;

        case kMachineGun:
        case kSubmachineGun:
            return kMachinegunFiring;

        case kLightCannon:
            return kArtilleryFiring;

        case kHeavyCannon:
            return kArtilleryFiring;

        case kMortar:
            return kMortarFiring;

        case kHowitzer:
            return kHowitzerFiring;

        case kFlamethrower:
            return kFlamethrowerFiring;
    }
}


- (float) projectileSpeed {
    // meters per second
    switch (self.type) {
        case kRifle:
        case kRifleMk2:
        case kSniperRifle:
            return 400;

        case kSubmachineGun:
            return 350;

        case kMachineGun:
            return 450;

        case kLightCannon:
            return 350;

        case kHeavyCannon:
            return 350;

        case kMortar:
            return 200;

        case kHowitzer:
            return 300;

        case kFlamethrower:
            // no projectiles here
            return 0;
    }
}


- (NSString *) projectileName {
    switch (self.type) {
        case kRifle:
        case kRifleMk2:
        case kSubmachineGun:
        case kMachineGun:
        case kSniperRifle:
            return @"RifleBullet.png";

        case kLightCannon:
            return @"CannonBullet.png";

        case kHeavyCannon:
        case kHowitzer:
            return @"CannonBullet.png";

        case kMortar:
            return @"MortarBullet.png";

        case kFlamethrower:
            // no projectiles here
            return nil;
    }
}


- (float) getFirepowerModifierForRange:(float)range {
    // under half range do nothing at all
    if (range < self.firingRange * 0.5f) {
        return 1.0f;
    }

    float firepowerAtMax;

    switch (self.type) {
        case kRifle:
            firepowerAtMax = 0.50f;
            break;

        case kRifleMk2:
            firepowerAtMax = 0.50f;
            break;

        case kSniperRifle:
            firepowerAtMax = 0.60f;
            break;

        case kSubmachineGun:
            firepowerAtMax = 0.40f;
            break;


        case kMachineGun:
            firepowerAtMax = 0.60f;
            break;

        case kLightCannon:
            firepowerAtMax = 0.75f;
            break;

        case kHeavyCannon:
        case kHowitzer:
            firepowerAtMax = 0.75f;
            break;

        case kMortar:
            firepowerAtMax = 0.75f;
            break;

        case kFlamethrower:
            firepowerAtMax = 0.5f;
            break;
    }

    float firingRange = self.firingRange;

    // interpolate from 1.0 down to the firepower at max range, giving a value 1.0 -> 0.x
    return (1.0f - (range - (firingRange * 0.5f)) / (firingRange * 0.5f)) * (1.0f - firepowerAtMax) + firepowerAtMax;
}


- (float) getScatterForRange:(float)range {
    float min, max;

    switch (self.type) {
        case kRifle:
            min = 10;
            max = 30;
            break;

        case kRifleMk2:
            min = 10;
            max = 20;
            break;

        case kSniperRifle:
            min = 7;
            max = 15;
            break;

        case kSubmachineGun:
            min = 15;
            max = 40;
            break;

        case kMachineGun:
            min = 10;
            max = 30;
            break;

        case kLightCannon:
            min = 20;
            max = 50;
            break;

        case kHeavyCannon:
            min = 20;
            max = 60;
            break;

        case kHowitzer:
            min = 30;
            max = 80;
            break;

        case kMortar:
            min = 30;
            max = 60;
            break;

        case kFlamethrower:
            min = 10;
            max = 50;
            break;
    }

    float firingRange = self.firingRange;

    // interpolate from min -> max
    return min + (max - min) * ((firingRange - range) / firingRange);
}


- (float) movementSpeedModifier {
    switch (self.type) {
        case kRifle:
        case kRifleMk2:
        case kSubmachineGun:
        case kSniperRifle:
            return 1.0f;

        case kMachineGun:
            return 0.9f;

        case kLightCannon:
            return 1.0f;

        case kHeavyCannon:
        case kHowitzer:
            return 0.8f;

        case kMortar:
            return 0.7f;

        case kFlamethrower:
            return 0.9f;
    }
}


- (int) menRequired {
    switch (self.type) {
        case kRifle:
        case kRifleMk2:
        case kSubmachineGun:
        case kSniperRifle:
            return 1;

        case kMachineGun:
            return 2;

        case kLightCannon:
            return 5;

        case kHeavyCannon:
        case kHowitzer:
            return 6;

        case kMortar:
            return 3;

        case kFlamethrower:
            return 2;
    }
}

- (BOOL) canFireSmoke {
    switch ( self.type ) {
        case kLightCannon:
        case kHeavyCannon:
        case kMortar:
        case kHowitzer:
            return YES;

        default:
            break;
    }

    // no smoke
    return NO;
}

@end
