
#import "HasMission.h"
#import "IdleMission.h"

@implementation HasMission

- (void) update {
    self.missionType = self.unit.mission.type;

    if ( self.unit.mission && self.unit.mission.type != kIdleMission ) {
        self.isTrue = YES;
    }
    else {
        self.isTrue = NO;
    }
}

@end
