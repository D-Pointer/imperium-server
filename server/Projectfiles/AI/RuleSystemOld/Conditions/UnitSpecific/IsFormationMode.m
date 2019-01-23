
#import "IsFormationMode.h"

@implementation IsFormationMode

- (void) update {
    self.isTrue = self.unit.mode == kFormation;
}

@end
