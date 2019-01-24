
#import "CCBReader.h"

#import "StartPrompt.h"
#import "Globals.h"
#import "Engine.h"
#import "Utils.h"

@implementation StartPrompt

@synthesize message;
@synthesize startButton;


+ (StartPrompt *) node {
    StartPrompt * node = (StartPrompt *)[CCBReader nodeGraphFromFile:@"StartPrompt.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    // set up the buttons
    [Utils createText:@"Start" forButton:self.startButton];
}


- (void) onEnter {
    [super onEnter];
    CCLOG( @"in" );

    // we handle touches, make sure we get before all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return NO;
    }
 
    CCLOG( @"hiding" );

    [self start];

    // we were visible, hide
    return YES;
}


- (void) start {
    CCLOG( @"in" );

    // hide now
    self.visible = NO;

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // no mre touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // start the engine ticking
    [[Globals sharedInstance].engine start];

    [self removeFromParentAndCleanup:YES];
}


@end
