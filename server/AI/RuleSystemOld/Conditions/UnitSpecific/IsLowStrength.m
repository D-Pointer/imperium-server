
#import "IsLowStrength.h"
#import "Scenario.h"

@implementation IsLowStrength

- (void) update {
    float percentage = (float)self.unit.men / (float)self.unit.originalMen;
    self.isTrue = percentage < 30;
    self.value = [NSNumber numberWithFloat:percentage];
}

@end
