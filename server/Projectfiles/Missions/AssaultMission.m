#import "AssaultMission.h"
#import "Unit.h"
#import "Globals.h"

@interface AssaultMission ()

@property (nonatomic, assign) BOOL started;

@end


@implementation AssaultMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kAssaultMission;
        self.name = @"Assaulting";
        self.preparingName = @"Preparing to assault";
        self.color = sAssaultLineColor;
        self.rotation = nil;
        self.started = NO;
        self.fatigueEffect = sParameters[kParamAssaultFatigueEffectF].floatValue;
    }

    return self;
}


- (id) initWithPath:(Path *)path {
    self = [super init];
    if (self) {
        self.unit = nil;
        self.path = path;
        self.type = kAssaultMission;
        self.name = @"Assaulting";
        self.preparingName = @"Preparing to assault";
        self.endPoint = path.lastPosition;
        self.color = sAssaultLineColor;
        self.started = NO;
        self.fatigueEffect = sParameters[kParamAssaultFatigueEffectF].floatValue;
    }

    return self;
}


- (MissionState) execute {
    // first time called?
    if (!self.started) {
        [[Globals sharedInstance].audio playSound:kAssaultOrdered];
        self.started = YES;
    }

    // can it still fire?
    if (![self.unit canFire]) {
        return kCompleted;
    }

    MissionState result = [self moveUnit:self.unit alongPath:self.path withSpeed:self.unit.assaultSpeed];

    // did we see any new enemy?
//    if ( [self checkForNewSeenEnemies:self.unit] ) {
//        // found new enemies
//        CCLOG( @"found new enemies" );
//        [self addMessage:kNewEnemySpotted forUnit:self.unit];
//    }

    return result;
}


@end
