
#import "RetreatMission.h"
#import "Unit.h"
#import "Globals.h"
#import "RotateMission.h"
#import "DisorganizedMission.h"

@interface RetreatMission ()

@property (nonatomic, assign) BOOL started;

@end


@implementation RetreatMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kRetreatMission;
        self.name = @"Retreating";
        self.preparingName = @"Preparing to retreat";
        self.color = sRetreatLineColor;
        self.started = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRetreatFatigueEffectF].floatValue;
    }

    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.path = path;
        self.type = kRetreatMission;
        self.name = @"Retreating";
        self.preparingName = @"Preparing to retreat";
        self.endPoint = path.lastPosition;
        self.color = sRetreatLineColor;
        self.started = NO;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamRetreatFatigueEffectF].floatValue;
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
    }

    // do the moving along the path
    MissionState result = [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.retreatSpeed];

    // was the moving completed?
    if ( result == kCompleted ) {
        // moving completed, be disorganized for a while
        DisorganizedMission * disorganizedMission = [DisorganizedMission new];

        // if this retreat mission can be cancelled
        disorganizedMission.fastReorganizing = self.canBeCancelled;
        self.unit.mission = disorganizedMission;

        // note that we return "in progress" here, otherwise the engine thinks the new disorganized mission is the
        // one that completed and removes it instead
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
