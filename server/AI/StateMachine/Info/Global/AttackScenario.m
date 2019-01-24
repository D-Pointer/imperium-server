
#import "AttackScenario.h"
#import "Globals.h"
#import "Scenario.h"
#import "UnitContext.h"

@implementation AttackScenario

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = -1;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    context.isAttackScenario = [Globals sharedInstance].scenario.aiHint == kPlayer2Attacks;
}

@end
