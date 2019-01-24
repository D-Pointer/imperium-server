
#import "Selector.h"
#import "NodeResult.h"

@interface Selector ()

@property (nonatomic, assign) unsigned int runningChildIndex;

@end


@implementation Selector

- (instancetype)init {
    self = [super init];
    if (self) {
        self.runningChildIndex = 0;
    }
    return self;
}


- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // create the result manually now instead of using the ready methods, as that puts the result in the wrong order
    NodeResult * result = [[NodeResult alloc] initWithNode:self result:kFailed];
    [context.blackboard.trace addObject:result];

    unsigned int startIndex = MAX( 0, self.runningChildIndex);

    for ( unsigned int index = startIndex; index < self.children.count; ++index ) {
        Node * child = self.children[ index ];
        switch ([child process:context] ) {
            case kFailed:
                // try next child
                continue;

            case kRunning:
                self.runningChildIndex = index;
                result.result = kRunning;
                return kRunning;

            case kSucceeded:
                // child succeeded, we've also succeeded
                self.runningChildIndex = 0;
                result.result = kSucceeded;
                return kSucceeded;
        }
    }

    // back to child 0
    self.runningChildIndex = 0;

    // all children failed
    result.result = kFailed;
    return kFailed;
}


@end
