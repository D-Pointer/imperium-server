
#import "FirstTurn.h"
#import "Clock.h"

@interface FirstTurn ()

@property (nonatomic, assign) BOOL isFirstTurn;

@end

@implementation FirstTurn

- (instancetype) init {
    self = [super init];
    if (self) {
        self.isFirstTurn = YES;
    }

    return self;
}


- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ GlobIsFirstTurn ] = @(self.isFirstTurn);

    // no longer the first turn
    self.isFirstTurn = NO;
}

@end
