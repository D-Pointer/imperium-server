
#import "Composite.h"

@implementation Composite

- (instancetype) init {
    self = [super init];
    if (self) {
        self.children = [NSMutableArray new];
    }

    return self;
}


- (NSString *) description {
    NSMutableArray * childDescriptions = [NSMutableArray array];
    for ( Node * node in self.children ) {
        [childDescriptions addObject:[node description]];
    }

    return [NSString stringWithFormat:@"[%@ %d children: %lu]", NSStringFromClass( [self class] ), self.nodeId, (unsigned long)self.children.count ];
}

@end
