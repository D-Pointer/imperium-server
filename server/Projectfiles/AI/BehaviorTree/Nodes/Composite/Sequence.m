
#import "Sequence.h"
#import "NodeResult.h"

@interface Sequence ()

@property (nonatomic, assign) unsigned int runningChildIndex;

@end


@implementation Sequence

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

    // have we already exe


    unsigned int startIndex = MAX( 0, self.runningChildIndex);

    for ( unsigned int index = startIndex; index < self.children.count; ++index ) {
        Node * child = self.children[ index ];
        switch ([child process:context] ) {
            case kFailed:
                // child failed, so we failed
                self.runningChildIndex = 0;
                result.result = kFailed;
                return kFailed;

            case kRunning:
                self.runningChildIndex = index;
                result.result = kRunning;
                return kRunning;

            case kSucceeded:
                continue;
        }
    }

    // back to child 0
    self.runningChildIndex = 0;

    // all children succeeded
    result.result = kSucceeded;
    return kSucceeded;
}


@end
