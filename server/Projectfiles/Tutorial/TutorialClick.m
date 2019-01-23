
#import "TutorialClick.h"

@interface TutorialClick ()

@property (nonatomic, assign) CGPoint    pos;
@property (nonatomic, assign) CGFloat    radius;

@end

@implementation TutorialClick
    
@synthesize pos;
@synthesize radius;

- (id) initWithClickPos:(CGPoint)pos_ radius:(CGFloat)radius_ {
    self = [super init];

    if (self) {
        self.pos    = pos_;
        self.radius = radius_;

        self.blocks = YES;
        
        // we pass through clicks once they are close enough
        self.claimTouch = NO;
    }
    
    return self;    
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    // nothing to do
}


- (void) cleanup {
    // nothing to do
}


- (BOOL) canProceed:(CGPoint)clickedPos {
    CGFloat distance = ccpDistance( self.pos, clickedPos );
    CCLOG( @"TutorialClick.canProceed: distance: %f", distance );
        
    return distance < self.radius;
}


@end
