
#import "If.h"
#import "NodeResult.h"

@interface If ()

@property (nonatomic, assign) unsigned int runningChildIndex;

@end


@implementation If

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

    if ( self.children.count != 3 ) {
        CCLOG( @"invalid number of children, expected 3, we have: %lu", (unsigned long)self.children.count );
        NSAssert( NO, @"invalid number of children" );
    }

    // run the condition
    switch ([self.children[0] process:context] ) {
        case kSucceeded:
            // true, run the second child
            result.result = [self returnResult:[self.children[1] process:context] context:context];
            break;

        case kFailed:
            // false, run the third child
            result.result = [self returnResult:[self.children[2] process:context] context:context];
            break;

        case kRunning:
            // condition still running
            result.result = [self running:context];
            break;
    }

    return result.result;
}


@end
