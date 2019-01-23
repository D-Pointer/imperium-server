
#import "State.h"

@implementation State

- (void) update:(UnitContext *)context forRuleSystem:(GKRuleSystem *)ruleSystem {
    NSAssert( NO, @"must be overridden" );
}

@end
