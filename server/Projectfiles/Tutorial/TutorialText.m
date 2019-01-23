
#import "TutorialText.h"
#import "Utils.h"
#import "Globals.h"
#import "GameLayer.h"

@interface TutorialText ()

@property (nonatomic, strong) CCSprite * background;
@property (nonatomic, strong) NSString * text;
@property (nonatomic, assign) CGPoint    pos;

@end

@implementation TutorialText

- (id) initWithText:(NSString *)text_ atPos:(CGPoint)pos_ {
    self = [super init];

    if (self) {
        self.text  = text_;
        self.pos   = pos_;

        // this version does not block by default
        self.blocks     = NO;
        self.claimTouch = NO;
    }

    return self;
}


- (id) initBlockingWithText:(NSString *)text_ atPos:(CGPoint)pos_ {
    self = [super init];

    if (self) {
        self.text  = text_;
        self.pos   = pos_;

        // this version blocks
        self.blocks     = YES;
        self.claimTouch = YES;
    }

    return self;
}


- (void) showPartInTutorial:(Tutorial *)tutorial {
    // first the background paper
    self.background = [CCSprite spriteWithSpriteFrameName:@"Tutorial/Paper.png"];
    self.background.position = self.pos;

    CCLabelBMFont * label = [CCLabelBMFont labelWithString:@"" fntFile:@"TutorialFont.fnt"];
    label.anchorPoint = ccp( 0.5, 0.5 );
    label.position = ccp( self.background.boundingBox.size.width * 0.5f, self.background.boundingBox.size.height * 0.5f );

    // and the description
    [Utils showString:self.text onLabel:label withMaxLength:250];

    // add all parts to the game layer
    [[Globals sharedInstance].gameLayer addChild:self.background z:kTutorialZ];
    [self.background addChild:label];
}


- (void) cleanup {
    // the background is simply faded out and then removed
    [self.background runAction:[CCSequence actions:
                            [CCFadeOut actionWithDuration:0.2f],
                            [CCCallFunc actionWithTarget:self selector:@selector(cleanupDone)],
                            nil]];
}


- (void) cleanupDone {
    [self.background stopAllActions];
    [self.background removeFromParentAndCleanup:YES];
    self.background = nil;
}



- (BOOL) canProceed:(CGPoint)clickedPos {
    // tapping anywhere is enough
    return YES;
}


@end
