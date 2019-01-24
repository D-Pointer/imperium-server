
#import "Action.h"

@implementation Action

- (instancetype) init {
    self = [super init];
    if (self) {
        self.name = NSStringFromClass([self class]);

        // default to not true
        self.isTrue = NO;

        // no unit by default
        self.foundUnit = nil;
    }

    return self;
}


- (BOOL) isFalse {
    return self.isTrue ? NO : YES;
}


- (void) update {
    // nothing to do by default
}

@end
