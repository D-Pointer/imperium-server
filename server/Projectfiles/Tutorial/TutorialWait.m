
#import "TutorialWait.h"

@interface TutorialWait ()

@property (nonatomic, assign) int seconds;

@end


@implementation TutorialWait


- (id) initWithTime:(int)seconds {
    self = [super init];

    if (self) {
        self.blocks = YES;
        self.claimTouch = NO;
        self.seconds = seconds;
    }

    return self;
}


- (BOOL) canProceed {
    // one more second done
    if ( --self.seconds == 0 ) {
        return YES;
    }

    // not yet
    return NO;
}

@end
