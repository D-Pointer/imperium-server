#import "Inverter.h"
#import "NodeResult.h"

@implementation Inverter

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kFailed];
    [context.blackboard.trace addObject:result];

    switch ([self.child process:context]) {
        case kFailed:
            result.result = kSucceeded;
            break;

        case kRunning:
            result.result = kRunning;
            break;

        case kSucceeded:
            result.result = kFailed;
            break;
    }

    return result.result;
}


@end
