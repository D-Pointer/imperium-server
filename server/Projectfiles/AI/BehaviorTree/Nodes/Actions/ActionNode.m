
#import "ActionNode.h"

@implementation ActionNode

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    // fetch the node specific data, if any
    NSObject * data = context.blackboard.nodeData[ @(context.unit.unitId)];

    // execute the node
    return [self process:context nodeData:data];
}


- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data {
    NSAssert( NO, @"must be overridden" );

    // never called
    return kFailed;
}

@end
