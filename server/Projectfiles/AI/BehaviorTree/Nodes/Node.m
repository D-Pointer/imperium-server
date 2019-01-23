
#import "Node.h"
#import "NodeResult.h"

static NSString * indentations[] = {
    @"",
    @"  ",
    @"    ",
    @"      ",
    @"        ",
    @"          ",
    @"            ",
    @"              ",
    @"                ",
    @"                  ",
    @"                    ",
    @"                      ",
    @"                        ",
    @"                          ",
    @"                            ",
};

@implementation Node

- (instancetype) init {
    self = [super init];
    if (self) {
        self.value = 0;
    }

    return self;
}


- (void) parseValue:(NSString *)value {
    self.value = [value intValue];
}


- (BehaviorTreeResult) process:(BehaviorTreeContext *)context {
    NSAssert( NO, @"must be overridden" );
    return [self failed:context];
}


- (NSString *) description {
    return [NSString stringWithFormat:@"[%@ %d]", NSStringFromClass( [self class] ), self.nodeId];
}


- (NSString *)indentedDescription {
    if ( self.nodeId == -1 ) {
        return [self description];
    }

    return [NSString stringWithFormat:@"%@%@", indentations[self.level], [self description]];
}


- (BehaviorTreeResult) failed:(BehaviorTreeContext *)context {
    [context.blackboard.trace addObject:[[NodeResult alloc] initWithNode:self result:kFailed]];
    return kFailed;
}


- (BehaviorTreeResult) running:(BehaviorTreeContext *)context {
    [context.blackboard.trace addObject:[[NodeResult alloc] initWithNode:self result:kRunning]];
    return kRunning;
}


- (BehaviorTreeResult) succeeded:(BehaviorTreeContext *)context {
    [context.blackboard.trace addObject:[[NodeResult alloc] initWithNode:self result:kSucceeded]];
    return kSucceeded;
}


- (BehaviorTreeResult) returnResult:(BehaviorTreeResult)result context:(BehaviorTreeContext *)context {
    switch ( result ) {
        case kSucceeded:
            return [self succeeded:context];
        case kFailed:
            return [self failed:context];
        case kRunning:
            return [self running:context];
    }
}

@end
