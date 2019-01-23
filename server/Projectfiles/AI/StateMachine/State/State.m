
#import "State.h"

@implementation State

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = NSStringFromClass( self.class );
    }
    
    return self;
}


- (void) evaluate:(UnitContext *)context {
    CCLOG( @"evaluating state %@ for %@", self.name, context.unit );
    [self realEvaluate:context];
}


- (void) realEvaluate:(UnitContext *)context {
    NSAssert( NO, @"must be overridden" );
}

@end
