
#import "CCBReader.h"

#import "HelpOverlay.h"
#import "Globals.h"
#import "GameLayer.h"
#import "Audio.h"


@implementation HelpOverlay

@synthesize pauseLabel;
@synthesize unitInfoLabel;
@synthesize changeModeLabel;
@synthesize autoFireLabel;
@synthesize centerLabel;
@synthesize nextUnitLabel;
@synthesize previousUnitLabel;
@synthesize hqLabel;
@synthesize cancelMissionLabel;
@synthesize changeModeLine;
@synthesize autoFireLine;
@synthesize centerLine;
@synthesize nextUnitLine;
@synthesize previousUnitLine;
@synthesize hqLine;
@synthesize cancelMissionLine;

+ (HelpOverlay *) node {
    return (HelpOverlay *)[CCBReader nodeGraphFromFile:@"HelpOverlay.ccb"];
}


- (void) didLoadFromCCB {
    // we handle touches now,our priority is after the menu above
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority - 1 swallowsTouches:YES];

    Unit * selectedUnit =  [Globals sharedInstance].selection.selectedUnit;

    // do we have a selected, own unit?
    if ( selectedUnit == nil || selectedUnit.owner != [Globals sharedInstance].localPlayer.playerId) {
        // no selected unit, hide those labels
        self.unitInfoLabel.visible = NO;
        self.changeModeLabel.visible = NO;
        self.autoFireLabel.visible = NO;
        self.centerLabel.visible = NO;
        self.nextUnitLabel.visible = NO;
        self.previousUnitLabel.visible = NO;
        self.hqLabel.visible = NO;
        self.cancelMissionLabel.visible = NO;

        // and lines
        self.changeModeLine.visible = NO;
        self.autoFireLine.visible = NO;
        self.centerLine.visible = NO;
        self.nextUnitLine.visible = NO;
        self.previousUnitLine.visible = NO;
        self.hqLine.visible = NO;
        self.cancelMissionLine.visible = NO;
    }
    else {
        // we have a unit, does it have a mission?
        if ( ! [selectedUnit isIdle] && selectedUnit.mission.canBeCancelled ) {
            self.cancelMissionLabel.visible = YES;
            self.cancelMissionLine.visible = YES;
        }
        else {
            self.cancelMissionLabel.visible = NO;
            self.cancelMissionLine.visible = NO;
        }

        if ( [selectedUnit canBeGivenMissions] ) {
            self.changeModeLabel.visible = YES;
            self.changeModeLine.visible = YES;
        }
        else {
            self.changeModeLabel.visible = NO;
            self.changeModeLine.visible = NO;
        }
    }

    // in multiplayer games we can not pause
    if ( [Globals sharedInstance].gameType == kMultiplayerGame ) {
        self.pauseLabel.visible = NO;
    }
}


- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    CCLOG( @"in" );

    // when we're hidden we don't handle touches
    if ( ! self.visible ) {
        CCLOG( @"not handling" );
        return YES;
    }

    // play a sound
    [[Globals sharedInstance].audio playSound:kButtonClicked];

    // no more touches, otherwise this will retain
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];

    [self removeFromParentAndCleanup:YES];

    return YES;
}

@end
