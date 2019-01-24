
#import "Info.h"

@implementation Info

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lastUpdated = -1;
        self.updateInterval = 10;
    }

    return self;
}


- (BOOL) updateRequired:(float)time {
    if ( _updateInterval < 0 ) {
        return NO;
    }
    
    return _lastUpdated < 0 || time > _lastUpdated + _updateInterval;
}


- (void) update:(UnitContext *)context {
    NSAssert( NO, @"must be overridden" );
}

@end
