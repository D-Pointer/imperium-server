#import "Failer.h"
#import "NodeResult.h"

@implementation Failer

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kFailed];
    [context.blackboard.trace addObject:result];

    // ignore the child result
    [self.child process:context];

    // always fail
    return kFailed;
}


@end
