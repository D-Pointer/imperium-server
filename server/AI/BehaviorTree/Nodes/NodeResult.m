
#import "NodeResult.h"

@implementation NodeResult

- (instancetype) initWithNode:(Node *)node result:(BehaviorTreeResult)result {
    self = [super init];
    if (self) {
        self.node = node;
        self.result = result;
    }

    return self;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ = %@", [self.node indentedDescription], self.result == kSucceeded ? @"succeeded" : (self.result == kFailed ? @"failed" : @"running")];
}

@end
