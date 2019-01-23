
#import "CCBReader.h"

#import "GameOptions.h"
#import "Globals.h"
#import "Engine.h"
#import "Audio.h"
#import "Utils.h"
#import "MissionVisualizer.h"
#import "MapLayer.h"
#import "Settings.h"

@implementation GameOptions

@synthesize menu;
@synthesize ambienceButton;
@synthesize sfxButton;
@synthesize commandButton;
@synthesize missionsButton;
@synthesize firingRangeButton;

+ (GameOptions *) node {
    GameOptions * node = (GameOptions *)[CCBReader nodeGraphFromFile:@"GameOptions.ccb"];
    return node;
}


- (void) didLoadFromCCB {
    // set the menu to have the highest priority
    self.menu.touchPriority = kCCMenuHandlerPriority - 2;

    // we handle touches now, make sure we get *before* all menus
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];

    // set up the checkmarks
    [self setupCheckmarks];
}


- (void) dealloc {
    CCLOG( @"in" );
    
    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );
    
    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        return YES;
    }

    // resume the engine
    [[Globals sharedInstance].engine resume];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    // kill ourselves
    [self removeFromParentAndCleanup:YES];

    return YES;
}


- (void) sfxToggled {
    Audio * audio = [Globals sharedInstance].audio;

    // play a sound
    [audio playSound:kButtonClicked];

    // toggle sound effects
    audio.soundsEnabled = audio.soundsEnabled ? NO : YES;

    [self setupCheckmarks];
}


- (void) ambienceToggled {
    Audio * audio = [Globals sharedInstance].audio;

    // play a sound
    [audio playSound:kButtonClicked];

    if ( audio.musicEnabled ) {
        audio.musicEnabled = NO;
    }
    else {
        audio.musicEnabled = YES;
        [audio playMusic:kInGameMusic];
    }

    [self setupCheckmarks];
}


- (void) commandToggled {
    [Settings sharedInstance].showCommandControl = [Settings sharedInstance].showCommandControl ? NO : YES;

    [self setupCheckmarks];

    // update the command range visualizer too
    [[Globals sharedInstance].mapLayer.commandRangeVisualizer updatePosition];
}


- (void) missionsToggled {
    [Settings sharedInstance].showAllMissions = [Settings sharedInstance].showAllMissions ? NO : YES;

    [self setupCheckmarks];

    // refresh all mission visualizers
    for ( Unit * unit in [Globals sharedInstance].units ) {
        if ( unit.missionVisualizer ) {
            [unit.missionVisualizer refresh];
        }
    }
}


- (void) firingRangeToggled {
    [Settings sharedInstance].showFiringRange = [Settings sharedInstance].showFiringRange ? NO : YES;

    [self setupCheckmarks];

    // update the firing range visualizer too
    [[Globals sharedInstance].mapLayer.rangeVisualizer updatePosition];
}


- (void) setupCheckmarks {
    Settings * settings = [Settings sharedInstance];
    Audio * audio = [Globals sharedInstance].audio;

    // ambient music
    if ( audio.musicEnabled ) {
        [Utils createImage:@"Buttons/Checkmark.png" withYOffset:0 forButton:self.ambienceButton];
    }
    else {
        [self.ambienceButton.normalImage removeAllChildren];
        [self.ambienceButton.selectedImage removeAllChildren];
    }

    if ( audio.soundsEnabled ) {
        [Utils createImage:@"Buttons/Checkmark.png" withYOffset:0 forButton:self.sfxButton];
    }
    else {
        [self.sfxButton.normalImage removeAllChildren];
        [self.sfxButton.selectedImage removeAllChildren];
    }

    if ( settings.showCommandControl ) {
        [Utils createImage:@"Buttons/Checkmark.png" withYOffset:0 forButton:self.commandButton];
    }
    else {
        [self.commandButton.normalImage removeAllChildren];
        [self.commandButton.selectedImage removeAllChildren];
    }

    if ( settings.showAllMissions ) {
        [Utils createImage:@"Buttons/Checkmark.png" withYOffset:0 forButton:self.missionsButton];
    }
    else {
        [self.missionsButton.normalImage removeAllChildren];
        [self.missionsButton.selectedImage removeAllChildren];
    }

    if ( settings.showFiringRange ) {
        [Utils createImage:@"Buttons/Checkmark.png" withYOffset:0 forButton:self.firingRangeButton];
    }
    else {
        [self.firingRangeButton.normalImage removeAllChildren];
        [self.firingRangeButton.selectedImage removeAllChildren];
    }
}


@end
