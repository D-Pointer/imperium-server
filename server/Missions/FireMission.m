#import "FireMission.h"
#import "RotateMission.h"
#import "Unit.h"
#import "Globals.h"
#import "Map.h"
#import "TerrainModifiers.h"
#import "LineOfSight.h"

@implementation FireMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kFireMission;
        self.name = @"Firing";
        self.preparingName = @"Preparing to fire";
        self.rotation = nil;

        // set later
        self.targetUnit = nil;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamFireFatigueEffectF].floatValue;
    }

    return self;
}


- (id) initWithTarget:(Unit *)target {
    self = [super init];
    if (self) {
        self.type = kFireMission;
        self.name = @"Firing";
        self.preparingName = @"Preparing to fire";
        self.endPoint = target.position;
        self.targetUnit = target;
        self.rotation = nil;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamFireFatigueEffectF].floatValue;
    }

    return self;
}


- (MissionState) execute {
    // has the target died? it can have been killed by another unit
    if (self.targetUnit == nil || self.targetUnit.destroyed || !self.targetUnit.visible) {
        return kCompleted;
    }

    // can it still fire?
    if (![self.unit canFire]) {
        return kCompleted;
    }

    // is the target now too far away?
    if (ccpDistance( self.unit.position, self.targetUnit.position ) > self.unit.weapon.firingRange) {
        NSLog( @"target is too far away" );
        return kCompleted;
    }

    // always update the end point in case the target unit moves
    self.endPoint = self.targetUnit.position;

    if (![self.unit isInsideFiringArc:self.targetUnit.position checkDistance:NO]) {
        // too big angle to the target, set up a rotation mission first. note that we make a smaller angle than needed!
        self.rotation = [[RotateMission alloc] initFacingTarget:self.targetUnit.position
                                                   maxDeviation:self.unit.weapon.firingAngle / 2.0f - 10.0f];
        NSLog( @"target is outside firing arc" );
    }

    // do we have a rotation mission still to do?
    if (self.rotation) {
        if ([self.rotation execute] == kCompleted) {
            // it is, so get rid of it
            self.rotation = nil;
            NSLog( @"rotation done" );
        }

        // start firing next update
        return kInProgress;
    }

    // when did the unit last fire?
    if (self.unit.lastFired + self.unit.weapon.reloadingTime > [Globals sharedInstance].clock.currentTime) {
        // still reloading
        return kInProgress;
    }

    bool targetSeen = YES;

    // check LOS
    if ( ! [self.unit.losData seesUnit:self.targetUnit] ) {
        // inside firing range but can not see the target. Was this a mortar unit with a HQ spotter?
        if (self.unit.weapon.type == kMortar || self.unit.weapon.type == kHowitzer) {
            // yes, so it could use its HQ as a spotter
            Unit *hq = self.unit.headquarter;

            // does it have an hq within command distance that is alive that can see the enemy?
            if (hq == nil || hq.destroyed) {
                NSLog( @"mortar hq destroyed or no hq at all, stopping indirect firing" );
                return kCompleted;
            }

            if (![hq isIdle]) {
                NSLog( @"mortar hq not idle, stopping indirect firing" );
                return kCompleted;
            }

            if (ccpDistance( self.unit.position, hq.position ) >= hq.commandRange) {
                NSLog( @"mortar hq too far away, stopping indirect firing" );
                return kCompleted;
            }

            if (![hq.losData seesUnit:self.targetUnit]) {
                // can not use HQ as spotter
                NSLog( @"mortar hq can not see target, stopping indirect firing" );
                return kCompleted;
            }

            // we do not see the target, but the HQ does
            targetSeen = NO;
        }
        else {
            // not a mortar unit so no LOS means we can't fire
            NSLog( @"no LOS to target" );
            return kCompleted;
        }
    }

    NSLog( @"***** %@ fires at %@", self.unit, self.targetUnit );

    // LOS to target, perform the actual attack
    [self fireAtTarget:self.targetUnit.position withUnit:self.unit targetSeen:targetSeen];

    return kInProgress;
}


@end
