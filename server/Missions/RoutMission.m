
#import "RoutMission.h"
#import "Unit.h"
#import "Globals.h"
#import "RotateMission.h"
#import "DisorganizedMission.h"

@interface RoutMission ()

@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL waitingForMorale;

@end


@implementation RoutMission

- (id) init {
    self = [super init];
    if (self) {
        self.type          = kRoutMission;
        self.name          = @"Routed";
        self.preparingName = @"Preparing to rout";
        self.color         = sRoutLineColor;

        self.started          = NO;
        self.waitingForMorale = NO;

        // this can not be cancelled by the player
        self.canBeCancelled = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRoutMovingFatigueEffectF].floatValue;
    }

    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.path          = path;
        self.type          = kRoutMission;
        self.name          = @"Routed";
        self.preparingName = @"Preparing to rout";
        self.endPoint      = path.lastPosition;
        self.color         = sRoutLineColor;

        self.started = NO;
        self.waitingForMorale = NO;

        // this can not be cancelled by the player
        self.canBeCancelled = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRoutMovingFatigueEffectF].floatValue;
    }

    return self;
}


- (float) commandDelay {
    // this never has any delay
    return -1;
}


- (MissionState) execute {
    // first time called?
    if ( ! self.started ) {
        [[Globals sharedInstance].audio playSound:kRetreatOrdered];
        self.started = YES;

        // turn the unit to face towards the first position of the retreat path
        if ( self.path && self.path.count > 0 ) {
            // set the facing to be along the path
            self.unit.rotation = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub(self.path.firstPosition, self.unit.position), ccp(0, 1) ) );
        }
    }

    // are we waiting for the morale to be high enough?
    if ( self.waitingForMorale ) {
        CCLOG( @"%@ waiting for morale to improve, now: %.1f", self.unit, self.unit.morale );

        if ( self.unit.morale < sParameters[kParamMaxMoraleRoutedF].floatValue ) {
            // still routed
            return kInProgress;
        }

        CCLOG( @"%@ morale ok, now disorganized", self.unit );

        // morale is better, be disorganized for a while
        DisorganizedMission * disorganizedMission = [DisorganizedMission new];

        // if this retreat mission can be cancelled
        disorganizedMission.fastReorganizing = NO;
        self.unit.mission = disorganizedMission;

        // note that we return "in progress" here, otherwise the engine thinks the new disorganized mission is the
        // one that completed and removes it instead
        return kInProgress;
    }

    // do the moving along the path
    MissionState result = [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.fastMovementSpeed];

    // was the moving completed?
    if ( result == kCompleted ) {
        // moving completed, now we wait for the morale to improve
        self.waitingForMorale = YES;

        // now the unit has arrived, it will now rest a bit
        self.fatigueEffect = sParameters[kParamRoutStandingFatigueEffectF].floatValue;
        return kInProgress;
    }

    return result;
}


- (NSString *) save {
    // target x, y, path
    return [NSString stringWithFormat:@"m %d %d %@\n",
            self.type,
            self.canBeCancelled ? 1 : 0,
            [self.path save]];
}


- (BOOL) loadFromData:(NSArray *)parts {
    // can we be cancelled?
    if ( [parts[0] intValue] == 1 ) {
        self.canBeCancelled = YES;
    }
    else {
        self.canBeCancelled = NO;
    }

    // load the path
    self.path = [Path pathFromData:parts startIndex:1];
    
    // all is ok
    return YES;
}


@end
