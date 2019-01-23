
#import "TutorialPart.h"

@implementation TutorialPart

@synthesize blocks;
@synthesize claimTouch;

- (id)init {
    self = [super init];
    if (self) {
        self.blocks = YES;
        
        // by default do not pass through clicks after proceeding
        self.claimTouch = YES;
    }
    
    return self;
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    // nothing to do    
}


- (BOOL) canProceed {
    return NO;
}


- (BOOL) canProceed:(CGPoint)clickedPos {
    return NO;
}


- (void) cleanup {
    // nothing to do
}


@end
