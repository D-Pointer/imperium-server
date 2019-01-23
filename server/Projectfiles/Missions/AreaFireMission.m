#import "AreaFireMission.h"
#import "RotateMission.h"
#import "Unit.h"
#import "Globals.h"
#import "MapLayer.h"
#import "TerrainModifiers.h"
#import "LineOfSight.h"

@interface AreaFireMission ()

@property (nonatomic, assign) CGPoint targetPos;

@end


@implementation AreaFireMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kAreaFireMission;
        self.name = @"Firing at area";
        self.preparingName = @"Preparing to fire";
        self.color = sAreaFireLineColor;
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
        self.type = kAreaFireMission;
        self.name = @"Firing at area";
        self.preparingName = @"Preparing to fire";
        self.endPoint = target;
        self.color = sAreaFireLineColor;
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

    // is the target now too far away?
    if (ccpDistance( self.unit.position, self.targetPos ) > self.unit.weapon.firingRange) {
        CCLOG( @"target is too far away" );
        return kCompleted;
    }

    if (![self.unit isInsideFiringArc:self.targetPos checkDistance:NO]) {
        // too big angle to the target, set up a rotation mission first. note that we make a smaller angle than needed!
        self.rotation = [[RotateMission alloc] initFacingTarget:self.targetPos
                                                   maxDeviation:self.unit.weapon.firingAngle / 2.0f - 10.0f];
        CCLOG( @"target is outside firing arc" );
    }

    // do we have a rotation mission still to do?
    if (self.rotation) {
        if ([self.rotation execute] == kCompleted) {
            // it is, so get rid of it
            self.rotation = nil;
            CCLOG( @"rotation done" );
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
    if ( ! [[Globals sharedInstance].mapLayer canSeeFrom:self.unit.position to:self.targetPos visualize:NO withMaxRange:self.unit.visibilityRange] ) {
        // inside firing range but can not see the target. Was this a mortar unit with a HQ spotter?
        if (self.unit.weapon.type == kMortar || self.unit.weapon.type == kHowitzer) {
            // yes, so it could use its HQ as a spotter
            Unit *hq = self.unit.headquarter;

            // does it have an hq within command distance that is alive that can see the enemy?
            if (hq == nil || hq.destroyed) {
                CCLOG( @"mortar hq destroyed or no hq at all, stopping indirect firing" );
                return kCompleted;
            }

            if (![hq isIdle]) {
                CCLOG( @"mortar hq not idle, stopping indirect firing" );
                return kCompleted;
            }

            if (ccpDistance( self.unit.position, hq.position ) >= hq.commandRange) {
                CCLOG( @"mortar hq too far away, stopping indirect firing" );
                return kCompleted;
            }

            if ( ! [[Globals sharedInstance].mapLayer canSeeFrom:hq.position to:self.targetPos visualize:NO withMaxRange:self.unit.visibilityRange] ) {
                // can not use HQ as spotter
                CCLOG( @"mortar hq can not see target, stopping indirect firing" );
                return kCompleted;
            }

            // we do not see the target, but the HQ does
            targetSeen = NO;
        }
        else {
            // not a mortar unit so no LOS means we can't fire
            CCLOG( @"no LOS to target" );
            return kCompleted;
        }
    }

    // LOS to target, perform the actual attack
    [self fireAtTarget:self.targetPos withUnit:self.unit targetSeen:targetSeen];

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
