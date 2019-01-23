
#import "CCBReader.h"

#import "QuitConfirm.h"
#import "Globals.h"
#import "Engine.h"
#import "Utils.h"
#import "GameLayer.h"

@implementation QuitConfirm

@synthesize message;
@synthesize quitButton;
@synthesize cancelButton;


+ (QuitConfirm *) node {
    QuitConfirm * node = (QuitConfirm *)[CCBReader nodeGraphFromFile:@"QuitConfirm.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    // set up the buttons
    [Utils createText:@"Quit" forButton:self.quitButton];
    [Utils createText:@"Cancel" forButton:self.cancelButton];
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

    [self cancel];

    // we were visible, hide
    return YES;
}


- (void) cancel {
    CCLOG( @"canceling popup" );
    
    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // no mre touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // resume the game
    [[Globals sharedInstance].engine resume];

    [self removeFromParentAndCleanup:YES];
}


- (void) quit {
    CCLOG( @"in" );

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // hide now
    self.visible = NO;

    // no more touches
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // just send a notification and someone else will quit for us
    [[NSNotificationCenter defaultCenter] postNotificationName:sNotificationQuitGame object:nil ];
}


@end
