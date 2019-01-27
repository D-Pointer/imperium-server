#import "SmokeMission.h"
#import "RotateMission.h"
#import "Unit.h"
#import "Globals.h"
#import "Map.h"
#import "TerrainModifiers.h"
#import "LineOfSight.h"

@interface SmokeMission ()

@property (nonatomic, assign) CGPoint targetPos;

@end


@implementation SmokeMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kSmokeMission;
        self.name = @"Firing smoke";
        self.preparingName = @"Preparing to fire";
        self.rotation = nil;

        // no target unit
        self.targetUnit = nil;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamFireFatigueEffectF].floatValue;
    }

    return self;
}


- (id) initWithTargetPosition:(CGPoint)target {
    self = [super init];
    if (self) {
        self.type = kSmokeMission;
        self.name = @"Firing smoke";
        self.preparingName = @"Preparing to fire";
        self.endPoint = target;
        self.rotation = nil;
        self.targetPos = target;

        // no target unit
        self.targetUnit = nil;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamFireFatigueEffectF].floatValue;
    }

    return self;
}


- (MissionState) execute {
    // can it still fire?
    if (![self.unit canFire]) {
        return kCompleted;
    }

    Weapon * weapon = self.unit.weapon;

    if ( weapon.ammo <= 0 ) {
        NSLog( @"out of ammo" );
        return kCompleted;
    }

    // is the target now too far away?
    if (ccpDistance( self.unit.position, self.targetPos ) > weapon.firingRange) {
        NSLog( @"target is too far away" );
        return kCompleted;
    }

    if (![self.unit isInsideFiringArc:self.targetPos checkDistance:NO]) {
        // too big angle to the target, set up a rotation mission first. note that we make a smaller angle than needed!
        self.rotation = [[RotateMission alloc] initFacingTarget:self.targetPos
                                                   maxDeviation:weapon.firingAngle / 2.0f - 10.0f];
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
    if (self.unit.lastFired + weapon.reloadingTime > [Globals sharedInstance].clock.currentTime) {
        // still reloading
        return kInProgress;
    }

    bool targetSeen = YES;

    // check LOS
    if ( ! [[Globals sharedInstance].map canSeeFrom:self.unit.position to:self.targetPos visualize:NO withMaxRange:self.unit.visibilityRange] ) {
        // inside firing range but can not see the target. Was this a mortar unit with a HQ spotter?
        if ( weapon.type == kMortar || weapon.type == kHowitzer) {
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

            if ( ! [[Globals sharedInstance].map canSeeFrom:hq.position to:self.targetPos visualize:NO withMaxRange:self.unit.visibilityRange] ) {
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

    // LOS to target, perform the actual attack
    float distanceToTarget = ccpDistance( self.unit.position, self.targetPos );

    // accuracy modifier for the range. this removes most of the efficiency
    float scatterDistance = [weapon getScatterForRange:distanceToTarget];
    NSLog( @"distance to target: %.0f m", distanceToTarget );
    NSLog( @"scatter: %.0f m", scatterDistance );

    // does the attacker see the target? if not we're dealing with indirect fire and the accuracy is worse
    if ( ! targetSeen ) {
        scatterDistance *= 1.5;
        NSLog( @"indirect fire, scatter: %.0f m", scatterDistance );
    }

    // the scatter is random too, sometimes it will simply hit bullseye
    scatterDistance *= CCRANDOM_0_1();
    NSLog( @"randomized scatter: %.2f m", scatterDistance );

    // scatter is reduced by experience
    switch ( self.unit.experience ) {
        case kGreen: scatterDistance *= 1.0f; break;
        case kRegular: scatterDistance *= 0.85f; break;
        case kVeteran: scatterDistance *= 0.70f; break;
        case kElite: scatterDistance *= 0.5f; break;
    }

    NSLog( @"experienced scatter: %.2f m", scatterDistance );

    // a final hit position scattered somewhere around the position we were aiming for
    float angle = (float)(CCRANDOM_0_1() * M_PI * 2);
    CGPoint hitPosition = ccp( self.targetPos.x + cosf( angle ) * scatterDistance,
                              self.targetPos.y + sinf( angle ) * scatterDistance );

    NSLog( @"target position: %.0f, %.0f", self.targetPos.x, self.targetPos.y );
    NSLog( @"hit position: %.0f, %.0f", hitPosition.x, hitPosition.y );
    
    // finally set up the attack visualization, but with no casualties -> smoke visualization
    [self createAttackVisualizationForAttacker:self.unit casualties:nil hitPosition:hitPosition];

    // record when the last attack was
    self.unit.lastFired = [Globals sharedInstance].clock.currentTime;

    // one less ammo
    weapon.ammo -= 1;

    //[self fireAtTarget:self.targetPos withUnit:self.unit targetSeen:targetSeen];

    return kInProgress;
}


- (NSString *) save {
    if ( self.rotation ) {
        // target x, y and endpoint x, y
        return [NSString stringWithFormat:@"m %d %.1f %.1f %.1f %.1f\n",
                self.type,
                self.rotation.target.x,
                self.rotation.target.y,
                self.targetPos.x,
                self.targetPos.y
                ];
    }
    else {
        // target x, y and endpoint x, y
        return [NSString stringWithFormat:@"m %d %.1f %.1f\n",
                self.type,
                self.targetPos.x,
                self.targetPos.y];
    }
}


- (BOOL) loadFromData:(NSArray *)parts {
    NSAssert( NO, @"not implemented" );
    return NO;
}

@end
