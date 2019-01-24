
#import "DefendScenario.h"
#import "Scenario.h"
#import "Globals.h"
#import "UnitContext.h"

@implementation DefendScenario

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = -1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    context.isDefendScenario = [Globals sharedInstance].scenario.aiHint == kPlayer1Attacks;
}

@end
