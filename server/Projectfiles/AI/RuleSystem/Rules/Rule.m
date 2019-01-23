
#import "Rule.h"

@implementation Rule

- (BOOL) evaluatePredicateWithSystem:(GKRuleSystem *)system {
    NSAssert( NO, @"must be overridden" );
    return NO;
}


- (void) performActionWithSystem:(GKRuleSystem *)system {
    NSAssert( NO, @"must be overridden" );
}

@end
