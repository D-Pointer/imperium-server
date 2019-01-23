
#import "CCBReader.h"

#import "Question.h"
#import "Globals.h"
#import "Utils.h"
#import "Layer.h"

@interface Question ()

@property (nonatomic, weak)   id<QuestionDelegate> delegate;

@end


@implementation Question

@synthesize buttonMenu;
@synthesize okButton;
@synthesize cancelButton;
@synthesize titleLabel;
@synthesize questionLabel;

+ (Question *) nodeWithQuestion:(NSString *)question titleText:(NSString *)title okText:(NSString *)okText cancelText:(NSString *)cancelText delegate:(id<QuestionDelegate>)delegate {
    Question * node = (Question *)[CCBReader nodeGraphFromFile:@"Question.ccb"];

    // set menu priority to be higher than normal
    node.buttonMenu.touchPriority = kCCMenuHandlerPriority - 1;

    // save the selectors
    node.delegate = delegate;

    // set up the buttons
    [Utils createText:okText forButton:node.okButton];
    [Utils createText:cancelText forButton:node.cancelButton];

    // title and question labels
    [Utils showString:title onLabel:node.titleLabel withMaxLength:260];
    [Utils showString:question onLabel:node.questionLabel withMaxLength:260];
    return node;
}


- (void) didLoadFromCCB {
}


- (void) onEnter {
    [super onEnter];
    CCLOG( @"in" );

    // we handle touches, make sure we get before all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority swallowsTouches:YES];
}


- (void) onExit {
    [super onExit];
    CCLOG( @"in" );

    // no mre touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return NO;
    }
 
    CCLOG( @"hiding" );

    // we were visible, hide
    return YES;
}


- (void) ok {
    CCLOG( @"in" );

    // play a sound
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // call the delegate if we got one
    if ( self.delegate && [self.delegate respondsToSelector:@selector(questionAccepted)] ) {
        [self.delegate questionAccepted];
    }

    // kill ourselves
    [self removeFromParentAndCleanup:YES];
}


- (void) cancel {
    CCLOG( @"in" );

    // play a sound
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // call the delegate if we got one
    if ( self.delegate && [self.delegate respondsToSelector:@selector(questionRejected)] ) {
        [self.delegate questionRejected];
    }

    // kill ourselves
    [self removeFromParentAndCleanup:YES];
}


@end
