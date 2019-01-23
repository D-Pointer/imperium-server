
#import "IsHalfStrength.h"
#import "Scenario.h"

@implementation IsHalfStrength

- (void) update {
    float percentage = (float)self.unit.men / (float)self.unit.originalMen;
    self.isTrue = percentage >= 30 && percentage < 70;
    self.value = [NSNumber numberWithFloat:percentage];
}

@end
