
#import "CCBReader.h"

#import "GameMenuPopup.h"
#import "Globals.h"
#import "Unit.h"
#import "GameSerializer.h"
#import "Help.h"
#import "GameLayer.h"
#import "Scenario.h"
#import "Audio.h"
#import "GameInfo.h"
#import "GameOptions.h"
#import "Utils.h"
#import "Engine.h"
#import "QuitConfirm.h"

@implementation GameMenuPopup

@synthesize titleLabel;
@synthesize subtitleLabel;
@synthesize helpButton;
@synthesize infoButton;
@synthesize quitButton;
@synthesize startButton;
@synthesize optionsButton;
@synthesize menu;

+ (GameMenuPopup *) node {
    return (GameMenuPopup *)[CCBReader nodeGraphFromFile:@"GameMenuPopup.ccb"];
}


- (void) didLoadFromCCB {
    // set the menu to have the highest priority
    self.menu.touchPriority = kCCMenuHandlerPriority - 2;

    // we handle touches now,our priority is after the menu above
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];

    // deployment menu and normal menu have different contents
    //    if ( [Globals sharedInstance].deploymentMode ) {
    //        // set up the buttons
    //        [Utils createText:@"Start" forButton:self.startButton];
    //        [Utils createText:@"Quit" forButton:self.quitButton];
    //    }
    //    else {
    // use the scenario as the title
    [self.titleLabel setString:[Globals sharedInstance].scenario.title];

    // base for the subtitle is the current turn
    [self.subtitleLabel setString:[NSString stringWithFormat:@"Time: %@", [[Globals sharedInstance].clock formattedTime]]];

    // set up the buttons
    [Utils createText:@"Help" forButton:self.helpButton];
    [Utils createText:@"Info" forButton:self.infoButton];
    [Utils createText:@"Quit" forButton:self.quitButton];
    [Utils createText:@"Options" forButton:self.optionsButton];
    //    }
}


- (void) dealloc {
    CCLOG( @"in" );
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );

    // when we're hidden we don't handle touches
    if ( self.visible == NO ) {
        CCLOG( @"not handling" );
        return YES;
    }

    // we were visible, hide
    [self hidePopup];

    // resume the engine
    [[Globals sharedInstance].engine resume];

    return YES;
}


- (void) hidePopup {
    CCLOG( @"in" );

    // don't close twice
    if ( ! self.visible ) {
        return;
    }

    self.quitButton.isEnabled = NO;

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    [self removeFromParentAndCleanup:YES];
}


- (void) help {
    CCLOG( @"in" );

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // hide ourselves
    [self hidePopup];

    // show the help
    CCScene * help = [Help inGameNode];
    [[CCDirector sharedDirector] pushScene:help];
}


- (void) quit {
    CCLOG( @"saving game" );
    [self hidePopup];

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // do not save the tutorial
    if ( [Globals sharedInstance].tutorial == nil ) {
        // no tutorial, what type of game? use different names per type
        switch ( [Globals sharedInstance].gameType ) {
            case kSinglePlayerGame:
                [GameSerializer saveGame:[NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId]];
                break;
            case kMultiplayerGame:
                [GameSerializer saveGame:sSaveFileNameMulti];
                break;
        }
    }

    CCLOG( @"showing confirm dialog" );

    QuitConfirm * popup = [QuitConfirm node];
    popup.position = ccp( 0, 0 );
    [[Globals sharedInstance].gameLayer addChild:popup z:kQuitPromptZ];
}


- (void) info {
    CCLOG( @"show info" );

    // add a new game info node
    GameInfo * gameInfo = [GameInfo node];
    [[Globals sharedInstance].gameLayer addChild:gameInfo z:kGameInfoZ];

    // get rid of ourselves
    [self hidePopup];
}


- (void) options {
    CCLOG( @"show options" );

    // add a new game info node
    GameOptions * options = [GameOptions node];
    [[Globals sharedInstance].gameLayer addChild:options z:kGameOptionsZ];

    // get rid of ourselves
    [self hidePopup];
}


- (void) start {
    CCLOG( @"in" );

    // get rid of ourselves
    [self hidePopup];
}

@end
