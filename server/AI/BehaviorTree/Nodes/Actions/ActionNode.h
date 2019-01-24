
#import "Node.h"

@interface ActionNode : Node

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context nodeData:(NSObject *)data;

@end
