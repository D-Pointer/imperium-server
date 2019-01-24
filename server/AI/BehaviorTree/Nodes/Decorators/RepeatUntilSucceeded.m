#import "RepeatUntilSucceeded.h"
#import "NodeResult.h"

@implementation RepeatUntilSucceeded

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kRunning];
    [context.blackboard.trace addObject:result];

    // loop until the node succeeds. We're running until it has succeeded

    //    while ( YES ) {
        switch ([self.child process:context]) {
            case kSucceeded:
                result.result = kSucceeded;
                return result.result;

            case kFailed:
//                // next loop
//                break;

            case kRunning:
                return result.result;
        }
        //    }
}

@end
