
#import "BehaviorTreeContext.h"


@implementation BehaviorTreeContext 

- (instancetype)init {
    self = [super init];
    if (self) {
        self.blackboard = [Blackboard new];
    }
    
    return self;
}
@end
