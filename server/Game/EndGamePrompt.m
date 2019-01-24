
#import "CCBReader.h"

#import "EndGamePrompt.h"
#import "Globals.h"
#import "Engine.h"
#import "Utils.h"

@implementation EndGamePrompt

@synthesize endGameButton;


+ (EndGamePrompt *) node {
    EndGamePrompt * node = (EndGamePrompt *)[CCBReader nodeGraphFromFile:@"EndGamePrompt.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    // set up the buttons
    [Utils createText:@"Quit" forButton:self.endGameButton];
}


- (void) onEnter {
    [super onEnter];
    CCLOG( @"in" );

    // we handle touches, make sure we get before all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority + 1 swallowsTouches:YES];
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


- (void) endGame {
    CCLOG( @"in" );

    // hide now
    self.visible = NO;

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    //[[NSNotificationCenter defaultCenter] postNotificationName:NotificationGameEnded object:nil ];
}


@end
