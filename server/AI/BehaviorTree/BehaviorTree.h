
#import "Node.h"
#import "BehaviorTreeContext.h"

@interface BehaviorTree : NSObject

@property (nonatomic, strong) Node * root;

- (void) executeWithContext:(BehaviorTreeContext *)context;

- (BOOL) readTree:(NSString *)filename;

@end