
#import "AdvanceMission.h"
#import "Unit.h"
#import "Globals.h"
#import "Engine.h"

@interface AdvanceMission ()

@property (nonatomic, assign) BOOL started;

@end


@implementation AdvanceMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kAdvanceMission;
        self.name = @"Advancing";
        self.preparingName = @"Preparing to advance";
        self.rotation = nil;
        self.started = NO;
        self.fatigueEffect = sParameters[kParamAdvanceFatigueEffectF].floatValue;
    }
    
    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.unit = nil;
        self.path = path;
        self.type = kAdvanceMission;
        self.name = @"Advancing";
        self.preparingName = @"Preparing to advance";
        self.endPoint = path.lastPosition;
        self.started = NO;
        self.fatigueEffect = sParameters[kParamAdvanceFatigueEffectF].floatValue;
    }
    
    return self;
}


- (MissionState) execute {
    // first time called?
    if ( ! self.started ) {
        self.started = YES;
    }

    // can it still fire?
    if ( ! [self.unit canFire]) {
        return kCompleted;
    }

    // when did the unit last fire?
    if ( self.unit.lastFired + self.unit.weapon.reloadingTime * sParameters[kParamAdvanceReloadingMultiplierF].floatValue <= [Globals sharedInstance].clock.currentTime ) {
        // it can fire, is there an enemy within the firing arc?
        self.targetUnit = [[Globals sharedInstance].engine findTarget:self.unit onlyInsideArc:YES];

        if ( self.targetUnit ) {
            // the target is valid, so fire at it
            [self fireAtTarget:self.targetUnit.position withUnit:self.unit targetSeen:YES];

            // continue moving next time
            return kInProgress;
        }
    }

    // the unit could not fire or did not find a target, so move instead
    MissionState result = [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.advanceSpeed];

    return result;
}


@end
