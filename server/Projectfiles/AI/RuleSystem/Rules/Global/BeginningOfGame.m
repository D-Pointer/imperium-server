
#import "BeginningOfGame.h"
#import "Clock.h"
#import "Globals.h"

@implementation BeginningOfGame

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    return [Globals sharedInstance].clock.elapsedTime < 300;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    [system assertFact:FactAttack grade:0.4f];
}

@end
