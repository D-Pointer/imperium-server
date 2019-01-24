
#import "HasHq.h"

@implementation HasHq

- (void) update {
    self.isTrue = self.unit.headquarter && [self.unit.headquarter canBeGivenMissions];
}

@end
