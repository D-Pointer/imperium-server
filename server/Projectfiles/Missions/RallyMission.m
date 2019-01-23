
#import "RallyMission.h"
#import "Unit.h"
#import "Globals.h"

@implementation RallyMission

- (id) init {
    self = [super init];
    if (self) {
        self.type          = kRallyMission;
        self.name          = @"Rallying unit";
        self.preparingName = @"Preparing to rally unit";
        self.color         = sRallyLineColor;
        self.fatigueEffect = sParameters[kParamRallyFatigueEffectF].floatValue;

        // set later
        self.targetUnit    = nil;
    }
    
    return self;
}

- (id) initWithTarget:(Unit *)target {
    self = [super init];
    if (self) {
        self.type          = kRallyMission;
        self.name          = [NSString stringWithFormat:@"Rallying %@", target.name];
        self.preparingName = [NSString stringWithFormat:@"Preparing to rally %@", target.name];
        self.endPoint      = target.position;
        self.color         = sRallyLineColor;
        self.targetUnit    = target;
        self.fatigueEffect = sParameters[kParamRallyFatigueEffectF].floatValue;
    }
    
    return self;
}


- (MissionState) execute {
    // has the target died? it can have been killed by another unit
    if ( self.unit == nil || self.unit.destroyed ) {
        return kCompleted;
    }

    // has the target died? it can have been killed by another unit
    if ( self.targetUnit == nil || self.targetUnit.destroyed ) {
        return kCompleted;
    }

    // is the target unit's morale now high enough?
    if ( self.targetUnit.morale >= sParameters[kParamMaxMoraleShakenF].floatValue ) {
        // morale high enough, we're done
        return kCompleted;
    }

    // still going, not high enough
    return kInProgress;
}


- (NSString *) save {
    return [NSString stringWithFormat:@"m %d %.1f %.1f\n",
            self.type,
            self.endPoint.x,
            self.endPoint.y ];
}


- (BOOL) loadFromData:(NSArray *)parts {
    // startTime completedTime endX endY
    self.endPoint  = CGPointMake( [parts[2] floatValue], [parts[3] floatValue] );

    int targetUnitId = -1;

    // all is ok
    return YES;
}

@end
