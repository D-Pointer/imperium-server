
#import "IsFullStrength.h"
#import "Scenario.h"

@implementation IsFullStrength

- (void) update {
    float percentage = (float)self.unit.men / (float)self.unit.originalMen;
    self.isTrue = percentage >= 70;
    self.value = [NSNumber numberWithFloat:percentage];
}

@end
