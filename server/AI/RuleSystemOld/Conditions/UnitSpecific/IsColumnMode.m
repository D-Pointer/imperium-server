
#import "IsColumnMode.h"
#import "Scenario.h"

@implementation IsColumnMode

- (void) update {
    self.isTrue = self.unit.mode == kColumn;
}

@end
