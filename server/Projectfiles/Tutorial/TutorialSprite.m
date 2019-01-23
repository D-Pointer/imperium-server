
#import "TutorialSprite.h"
#import "Globals.h"
#import "GameLayer.h"

@interface TutorialSprite ()

@property (nonatomic, strong) CCSprite * sprite;
@property (nonatomic, strong) NSString * frameName;
@property (nonatomic, assign) CGPoint    pos;

@end

@implementation TutorialSprite
    
@synthesize sprite;
@synthesize frameName;
@synthesize pos;

- (id) initWithFrame:(NSString *)frameName_ atPos:(CGPoint)pos_ {
    self = [super init];

    if (self) {
        self.sprite    = nil;
        self.frameName = frameName_;
        self.pos       = pos_;

        // this version does not block by default
        self.blocks = NO;
    }
    
    return self;    
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    self.sprite = [CCSprite spriteWithSpriteFrameName:self.frameName];
    self.sprite.position = self.pos;
    [[Globals sharedInstance].gameLayer addChild:self.sprite z:kTutorialZ];
    
    // scale up and down
    [self.sprite runAction:[CCRepeatForever actionWithAction:
                            [CCSequence actions:
                             [CCScaleTo actionWithDuration:0.5 scale:0.95],
                             [CCScaleTo actionWithDuration:0.5 scale:1.05], 
                             nil]]];
}


- (void) cleanup {
    // stop the animation
    [self.sprite stopAllActions];
    
    // get rid of the label
    [self.sprite runAction:[CCSequence actions:
                            [CCFadeOut actionWithDuration:0.2f],
                            [CCCallFunc actionWithTarget:self selector:@selector(cleanupDone)],
                            nil]];
}


- (void) cleanupDone {
    [self.sprite removeFromParentAndCleanup:YES];
    self.sprite = nil;
}



- (BOOL) canProceed:(CGPoint)clickedPos {
    // tapping anywhere is enough
    return YES;
}


@end
