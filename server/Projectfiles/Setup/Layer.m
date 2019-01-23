#import "Layer.h"
#import "Utils.h"
#import "NetworkError.h"
#import "Question.h"
#import "MainMenu.h"

@interface Layer ()

@property (nonatomic, strong) NSMutableArray *nodes;
@property (nonatomic, assign) BOOL animating;
@property (nonatomic, strong) CCScene *sceneToReplace;

@end


@implementation Layer

- (id) init {
    self = [super init];
    if (self) {
        self.nodes = [NSMutableArray new];
        self.animating = NO;
        self.sceneToReplace = nil;
    }

    return self;
}


- (void) onEnter {
    [super onEnter];
    self.animating = NO;
}


- (void) moveNode:(CCNode *)node toPos:(CGPoint)pos inTime:(CGFloat)time atRate:(CGFloat)rate {
    [node runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:time position:pos]
                                          rate:rate]];
}


- (void) scaleNode:(CCNode *)node toScale:(CGFloat)scale inTime:(CGFloat)time {
    [node runAction:[CCScaleTo actionWithDuration:time scale:scale]];
}


- (void) rotateNode:(CCNode *)node toAngle:(CGFloat)angle inTime:(CGFloat)time atRate:(CGFloat)rate {
    [node runAction:[CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:time angle:angle]
                                          rate:rate]];
}


- (void) fadeNode:(CCNode *)node toAlpha:(GLubyte)alpha inTime:(CGFloat)time atRate:(CGFloat)rate {
    [node runAction:[CCEaseIn actionWithAction:[CCFadeTo actionWithDuration:time opacity:alpha]
                                          rate:rate]];
}


- (void) fadeNode:(CCNode<CCRGBAProtocol> *)node fromAlpha:(GLubyte)fromAlpha toAlpha:(GLubyte)toAlpha afterDelay:(CGFloat)delay inTime:(CGFloat)time {
    node.opacity = fromAlpha;
    [node runAction:[CCSequence actions:
                     [CCDelayTime actionWithDuration:delay],
                     [CCFadeTo actionWithDuration:time opacity:toAlpha],
                     nil]];

    for ( CCNode * child in node.children ) {
        if ( [child conformsToProtocol:@protocol(CCRGBAProtocol) ] ) {
            CCNode<CCRGBAProtocol> * childNode = (CCNode<CCRGBAProtocol> *)child;
            [self fadeNode:childNode fromAlpha:fromAlpha toAlpha:toAlpha afterDelay:delay inTime:time];
        }
    }
}


- (void) addAnimatableNode:(CCNode *)node {
    [self.nodes addObject:node];
}


- (void) removeAnimatableNode:(CCNode *)node {
    [self.nodes removeObject:node];
}


- (void) animateNodesAway {
    CGPoint center = CGPointMake( 512, 384 );

    // animate out all nodes
    for (CCNode *node in self.nodes) {
        // no own animations
        [node stopAllActions];

        // direction vector from the middle
        CGPoint direction = ccpNormalize( ccpSub( node.position, center ) );

        // the destination follows the direction for "some way"
        CGPoint destination = ccpAdd( node.position, ccpMult( direction, 500 + node.boundingBox.size.width ) );

        // a random destination angle
        float angle = -90 + CCRANDOM_0_1() * 180;

        // animate out
        [self moveNode:node toPos:destination inTime:0.5f atRate:1.5f];
        [self rotateNode:node toAngle:angle inTime:0.5f atRate:2.0f];
        [self scaleNode:node toScale:1.5f inTime:0.5f];
    }
}


- (void) animateNodesAwayWithSelector:(SEL)selector {
    // are we already animating?
    if (self.animating) {
        return;
    }

    // now we are
    self.animating = YES;

    // do the real animating
    [self animateNodesAway];

    // in 1s the scene is done, call the given selector
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:selector forTarget:self interval:1.0f repeat:0 delay:0 paused:NO];
}


- (void) animateNodesAwayAndShowScene:(CCScene *)scene {
    // are we already animating?
    if (self.animating) {
        return;
    }

    // now we are
    self.animating = YES;

    self.sceneToReplace = scene;

    // do the real animating
    [self animateNodesAway];

    // in 1s the scene is done, call the given selector
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector( animateNodesAwayAndShowSceneCallback ) forTarget:self interval:1.0f repeat:0 delay:0 paused:NO];
}


- (void) disableBackButton:(CCMenuItemImage *)backButton {
    // disable and fade out
    [backButton setIsEnabled:NO];
    [backButton runAction:[CCFadeOut actionWithDuration:0.3f]];
}


- (void) animateNodesAwayAndShowSceneCallback {
    if (self.sceneToReplace == nil) {
        [[CCDirector sharedDirector] popScene];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:self.sceneToReplace];
    }
}


- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button {
    [Utils createText:text forButton:button];
}


- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button includeDisabled:(BOOL)includeDisabled {
    [Utils createText:text forButton:button includeDisabled:includeDisabled];
}


- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName {
    [Utils createText:text forButton:button withFont:fontName];
}


- (void) createImage:(NSString *)frameName forButton:(CCMenuItemSprite *)button {
    [Utils createImage:frameName forButton:button];
}


- (void) showErrorScreen:(NSString *)errorMessage {
    CCLOG( @"showing error message: %@", errorMessage );
    CCScene *errorScene = [NetworkError nodeWithMessage:errorMessage backScene:[MainMenu node]];

    // show the scene replacing anything that's on right now
    [[CCDirector sharedDirector] replaceScene:errorScene];
}


- (void) showErrorScreen:(NSString *)errorMessage backScene:(CCScene *)backScene {
    CCLOG( @"showing error message: %@", errorMessage );
    CCScene *errorScene = [NetworkError nodeWithMessage:errorMessage backScene:backScene];

    // show the scene replacing anything that's on right now
    [[CCDirector sharedDirector] replaceScene:errorScene];
}


- (void) askQuestion:(NSString *)question withTitle:(NSString *)title okText:(NSString *)okText cancelText:(NSString *)cancelText delegate:(id <QuestionDelegate>)delegate {
    // single player game, show an end prompt
    Question *prompt = [Question nodeWithQuestion:question titleText:title okText:okText cancelText:cancelText delegate:delegate];
    prompt.position = ccp( 0, 0 );
    [self addChild:prompt z:kQuestionPromptZ];
}


@end
