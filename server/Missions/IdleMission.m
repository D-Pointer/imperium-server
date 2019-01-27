
#import "IdleMission.h"
#import "Unit.h"
#import "Globals.h"

@implementation IdleMission

- (id) init {
    self = [super init];
    if (self) {
        self.type = kIdleMission;
        self.name = @"No mission";
        self.preparingName = @"No mission";

        // this can be cancelled by the player
        self.canBeCancelled = YES;

        // fatigue added per minute
        self.fatigueEffect = sParameters[kParamIdleFatigueEffectF].floatValue;
     }

    return self;
}


- (float) commandDelay {
    // this never has any delay
    return -1;
}


- (MissionState) execute {
    // never ends
    return kInProgress;
}


- (NSString *) save {
    return [NSString stringWithFormat:@"m %d\n",
            self.type ];
}


- (BOOL) loadFromData:(NSArray *)parts {
    // nothing to do, all is ok
    return YES;
}


@end
