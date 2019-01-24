
#import "HasTarget.h"
#import "CombatMission.h"

@implementation HasTarget

- (void) update {
    if ( self.unit.mission && [self.unit.mission isKindOfClass:[CombatMission class]] ) {
        self.isTrue = YES;
    }
    else {
        self.isTrue = NO;
    }
}

@end
