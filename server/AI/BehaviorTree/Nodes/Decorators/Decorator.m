
#import "Decorator.h"

@implementation Decorator

- (NSString *) description {
    return [NSString stringWithFormat:@"[%@ %d]", NSStringFromClass( [self class] ), self.nodeId];
}

@end
