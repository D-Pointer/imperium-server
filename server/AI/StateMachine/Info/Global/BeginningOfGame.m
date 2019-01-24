
#import "BeginningOfGame.h"
#import "Clock.h"
#import "Globals.h"
#import "UnitContext.h"

@implementation BeginningOfGame

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    context.isBeginningOfGame = [Globals sharedInstance].clock.elapsedTime < 300;
}

@end
