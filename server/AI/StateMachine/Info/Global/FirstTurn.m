
#import "FirstTurn.h"
#import "Clock.h"
#import "UnitContext.h"

@interface FirstTurn()

@property (nonatomic, assign) BOOL firstUpdateDone;

@end


@implementation FirstTurn

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 1;
        self.firstUpdateDone = NO;
    }
    return self;
}


- (void) update:(UnitContext *)context {
    if ( _firstUpdateDone == NO ) {
        context.isFirstTurn = YES;
        _firstUpdateDone = YES;
    }
    else {
        context.isFirstTurn = NO;
    }
}

@end
