
#import "cocos2d.h"
#import "QuestionDelegate.h"

@interface Layer : CCLayer

- (void) moveNode:(CCNode *)node toPos:(CGPoint)pos inTime:(CGFloat)time atRate:(CGFloat)rate;
- (void) scaleNode:(CCNode *)node toScale:(CGFloat)scale inTime:(CGFloat)time;
- (void) rotateNode:(CCNode *)node toAngle:(CGFloat)angle inTime:(CGFloat)time atRate:(CGFloat)rate;
- (void) fadeNode:(CCNode *)node toAlpha:(GLubyte)alpha inTime:(CGFloat)time atRate:(CGFloat)rate;
- (void) fadeNode:(CCNode<CCRGBAProtocol> *)node fromAlpha:(GLubyte)fromAlpha toAlpha:(GLubyte)toAlpha afterDelay:(CGFloat)delay inTime:(CGFloat)time;

- (void) addAnimatableNode:(CCNode *)node;
- (void) removeAnimatableNode:(CCNode *)node;

- (void) animateNodesAwayWithSelector:(SEL)selector;
- (void) animateNodesAwayAndShowScene:(CCScene *)scene;

- (void) disableBackButton:(CCMenuItemImage *)backButton;

- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button;
- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button includeDisabled:(BOOL)includeDisabled;
- (void) createText:(NSString *)text forButton:(CCMenuItemSprite *)button withFont:(NSString *)fontName;
- (void) createImage:(NSString *)frameName forButton:(CCMenuItemSprite *)button;

/**
 * Shows a network error screen.
 **/
- (void) showErrorScreen:(NSString *)errorMessage;

- (void) showErrorScreen:(NSString *)errorMessage backScene:(CCScene *)backScene;

- (void) askQuestion:(NSString *)question withTitle:(NSString *)title okText:(NSString *)okText cancelText:(NSString *)cancelText delegate:(id<QuestionDelegate>)delegate;

@end
