
#import "ConditionNode.h"

@interface ConditionNode ()

// world time when the condition was last updated
@property (nonatomic, assign) float lastUpdated;

// frequency of updates in world time seconds
@property (nonatomic, assign) float frequency;

@property (nonatomic, assign) BehaviorTreeResult cachedValue;

@end


@implementation ConditionNode

- (instancetype) init {
    self = [super init];
    if (self) {
        self.lastUpdated = -1000;
        self.frequency = 0;
    }

    return self;
}


- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    CCLOG( @"processing node %@", self );

    // time to update?
    if ( self.lastUpdated + self.frequency < context.elapsedTime ) {
        // update our cached value
        self.lastUpdated = context.elapsedTime;
        self.cachedValue = [self update:context];
    }

    return [self returnResult:self.cachedValue context:context];
}


- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    NSAssert( NO, @"must be overridden" );
    return kFailed;
}

@end
