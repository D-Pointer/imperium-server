
#import "SeesEnemies.h"
#import "Globals.h"
#import "LineOfSight.h"

@implementation SeesEnemies

- (void) update {
    NSUInteger seen = self.unit.losData.seenCount; 
    self.value = [NSNumber numberWithUnsignedInteger:seen];
    self.isTrue = seen > 0;
}

@end
