
#import "Morale.h"

@implementation Morale

- (void) update {
    // this is always true, the condition value is the real beef
    self.isTrue = YES;
    self.value = [NSNumber numberWithFloat:self.unit.morale];
}

@end
