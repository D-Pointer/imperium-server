#import "Repeater.h"
#import "NodeResult.h"

@implementation Repeater

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kFailed];
    [context.blackboard.trace addObject:result];

    // TODO: the index must be stored and each tick would increment it, not run all at once as now
    
    for (unsigned int index = 0; index < self.value; ++index) {
        switch ([self.child process:context]) {
            case kFailed:
            case kSucceeded:
                result.result = kSucceeded;
                return result.result;

            case kRunning:
                result.result = kRunning;
                return result.result;
        }
    }

    // can never be reached
    return kFailed;
}

@end
