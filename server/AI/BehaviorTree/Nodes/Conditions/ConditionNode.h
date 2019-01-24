
#import "Node.h"
#import "Globals.h"

@interface ConditionNode : Node

// subclasses update their value here
- (BehaviorTreeResult) update:(BehaviorTreeContext *)context;

@end
