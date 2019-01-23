
#import "Rule.h"
#import "Action.h"

@implementation Rule

- (instancetype) initWithPriority:(int)priority {
    self = [super init];
    if (self) {
        self.name = NSStringFromClass([self class]);
        self.priority = priority;
    }

    return self;
}


- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions {
    NSAssert( NO, @"must be overridden" );
    return NO;
}


- (CCSprite *) createDebuggingNode {
    NSAssert( NO, @"must be overridden" );
}


- (NSString *)description {
    return [NSString stringWithFormat:@"[%@, %d]", self.name, self.priority];
}

@end
