
#import "PauseButton.h"
#import "Globals.h"
#import "Utils.h"
#import "Definitions.h"
#import "Engine.h"

@interface PauseButton ()

@property (nonatomic, strong) CCMenuItemSprite * pauseButton;

@end


@implementation PauseButton

- (id)init {
    self = [super init];
    if (self) {
        // in game menu button
        CCSprite * normal = [CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1.png"];
        CCSprite * pressed = [CCSprite spriteWithSpriteFrameName:@"Buttons/ButtonSmall1Pressed.png"];
        self.pauseButton = [CCMenuItemSprite itemWithNormalSprite:normal selectedSprite:pressed target:self selector:@selector(buttonPressed)];
        self.pauseButton.position = ccp( 0, 0 );

        // set up the text
        [Utils createImage:@"Buttons/Pause.png" withYOffset:0 forButton:self.pauseButton];

        CCMenu * menu = [CCMenu menuWithItems:self.pauseButton, nil];
        menu.position = ccp( 0, 0 );
        [self addChild:menu];        

        // we want to know when the engine changes state
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(engineStateChanged) name:sNotificationEngineStateChanged object:nil];
    }
    
    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) buttonPressed {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // play a sound
    [globals.audio playSound:kButtonClicked];

    // currently paused?
    if ( globals.engine.isPaused ) {
        [globals.engine resume];
    }
    else {
        [globals.engine pause];
    }
}


- (void) engineStateChanged {
    // currently paused?
    if ( [Globals sharedInstance].engine.isPaused ) {
        // paused, show a play button
        [Utils createImage:@"Buttons/Play.png" withYOffset:0 forButton:self.pauseButton];
    }
    else {
        // playing, show a pause button
        [Utils createImage:@"Buttons/Pause.png" withYOffset:0 forButton:self.pauseButton];
    }
}

@end
