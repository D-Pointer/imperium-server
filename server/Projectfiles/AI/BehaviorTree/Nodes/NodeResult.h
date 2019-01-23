
#import "Node.h"

@interface NodeResult : NSObject

@property (nonatomic, weak) Node * node;
@property (nonatomic, assign) BehaviorTreeResult result;

- (instancetype) initWithNode:(Node *)node result:(BehaviorTreeResult)result;

@end
