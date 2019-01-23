
#import "Succeeder.h"
#import "NodeResult.h"

@implementation Succeeder

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kSucceeded];
    [context.blackboard.trace addObject:result];

    // ignore the child result
    [self.child process:context];

    // always succeed
    return kSucceeded;
}


@end
