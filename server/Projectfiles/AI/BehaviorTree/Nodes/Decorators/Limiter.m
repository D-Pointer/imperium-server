#import "Limiter.h"
#import "NodeResult.h"

@interface Limiter ()
@property (nonatomic, assign) int calls;

@end

@implementation Limiter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.calls = 0;
    }
    
    return self;
}


- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kFailed];
    [context.blackboard.trace addObject:result];

    // TODO: should it return running?
    // TODO: when are calls reset?

    if ( self.calls < self.value ) {
        self.calls++;
        result.result = [self.child process:context];
        return result.result;
    }

    result.result = kFailed;
    return result.result;
}

@end
