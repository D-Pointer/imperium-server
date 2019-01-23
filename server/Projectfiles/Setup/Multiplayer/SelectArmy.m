
#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "SelectArmy.h"
#import "MainMenu.h"
#import "Globals.h"
#import "Utils.h"
#import "Army.h"
#import "EditArmy.h"
#import "UnitDefinition.h"
#import "Lobby.h"
#import "ComingSoon.h"


@interface SelectArmy ()

@property (nonatomic, assign) unsigned int selectedIndex;
@end


@implementation SelectArmy

@synthesize editButton;
@synthesize playButton;
@synthesize backButton;
@synthesize army1Button;
@synthesize army2Button;
@synthesize army3Button;
@synthesize unitListPaper;
@synthesize helpPaper;
@synthesize armiesPaper;
@synthesize armyNameLabel;
@synthesize unitListLabel;
@synthesize noUnitsLabel;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"SelectArmy.ccb"];
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Army 1" forButton:self.army1Button];
    [self createText:@"Army 2" forButton:self.army2Button];
    [self createText:@"Army 3" forButton:self.army3Button];
    [self createText:@"Edit" forButton:self.editButton];
    [self createText:@"Play" forButton:self.playButton];
    [self createText:@"Back" forButton:self.backButton];

    Globals *globals = [Globals sharedInstance];

    for ( unsigned int index = 0; index < 3; ++index ) {
        if (globals.armies[index] == globals.currentArmy) {
            self.selectedIndex = index;
        }
    }

    [Globals sharedInstance].currentArmy = [Globals sharedInstance].armies[ self.selectedIndex ];

    // show tge default army
    [self showArmy];

    // analytics
    [Answers logCustomEventWithName:@"Select army"
                   customAttributes:@{} ];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.unitListPaper.position = ccp( 1600, 800 );
    self.unitListPaper.rotation = -50;
    self.unitListPaper.scale = 2.0f;

    self.helpPaper.position = ccp( 300, -500 );
    self.helpPaper.rotation = 50;
    self.helpPaper.scale = 2.0f;

    self.armiesPaper.position = ccp( -300, 200 );
    self.armiesPaper.rotation = 50;
    self.armiesPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.helpPaper toPos:ccp(395, 140) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.helpPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.helpPaper toAngle:-3 inTime:0.5f atRate:0.5f];

    [self moveNode:self.armiesPaper toPos:ccp(215, 400) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.armiesPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.armiesPaper toAngle:-2 inTime:0.5f atRate:0.5f];

    // these can be animated
    [self addAnimatableNode:self.unitListPaper];
    [self addAnimatableNode:self.helpPaper];
    [self addAnimatableNode:self.armiesPaper];

    // animate in the initial army
    [self animateInArmy];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];

    // we're an online delegate
    [[Globals sharedInstance].tcpConnection registerDelegate:self];
}

- (void) onExit {
    [super onExit];

    // we're no longer an online delegate
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) selectArmy:(id)sender {
    CCLOG( @"in" );
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // don't animate if the same was already selected
    if ( self.selectedIndex == ((CCMenuItemImage *)sender).tag ) {
        return;
    }

    self.selectedIndex = (int)((CCMenuItemImage *)sender).tag;
    [Globals sharedInstance].currentArmy = [Globals sharedInstance].armies[ self.selectedIndex ];

    [self animateOutArmy];

    // disable and fade out back button
    [self disableBackButton:self.backButton];
}


- (void) editArmy {
    CCLOG( @"in" );
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    [self animateNodesAwayAndShowScene:[EditArmy node]];

    // disable and fade out back button
    [self disableBackButton:self.backButton];
}


- (void) proceed {
    Globals *globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    if ( sOnlineEnabled ) {
        // get the previous name
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString * onlineName = [defaults stringForKey:@"onlineName"];

        CCLOG( @"logging in to network server as: %@", onlineName );
        [globals.tcpConnection loginWithName:onlineName];
    }
    else {
        // no online avaiable yet
        [self animateNodesAwayAndShowScene:[ComingSoon node]];
    }

    // disable and fade out back button
    [self disableBackButton:self.backButton];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    [self animateNodesAwayAndShowScene:[MainMenu node]];
}


- (void) showArmy {
    Globals *globals = [Globals sharedInstance];

    NSAssert( self.selectedIndex < globals.armies.count, @"invalid army index" );

    // try to announce the scenario
    CCLOG( @"selecting army: %d", self.selectedIndex );

    // name of the army
    [self.armyNameLabel setString:[NSString stringWithFormat:@"Army %d", self.selectedIndex + 1]];

    // assemble all the unit names of the army into a list
    NSMutableArray * names = [NSMutableArray array];
    Army * army = globals.armies[ self.selectedIndex ];

    // any units at all?
    if ( army.unitDefinitions.count == 0 ) {
        // just show a label and hide the Play button
        [self.noUnitsLabel setString:@"No units in the army. Tap Edit to set up\nunits for this army. Armies are saved\nfor future battles."];
        self.noUnitsLabel.visible = YES;
        self.unitListLabel.visible = NO;
        self.playButton.visible = NO;
        return;
    }

    // create a list of the units in the army. Merge several of the same type into "3 x infantry" etc. This is quite
    // ugly but works ok
    unsigned int definitions[ kFlamethrowerTeamDef + 1 ];
    for ( int index = 0; index <= kFlamethrowerTeamDef; ++index ) {
        definitions[ index ] = 0;
    }

    for ( UnitDefinition * unitDef in army.unitDefinitions ) {
        definitions[unitDef.type] += 1;
    }

    for ( int index = 0; index < kFlamethrowerTeamDef; ++index ) {
        if ( definitions[ index ] == 1 ) {
            [names addObject:[UnitDefinition name:index]];
        }
        else if ( definitions[ index ] > 1 ) {
            [names addObject:[NSString stringWithFormat:@"%d x %@", definitions[ index ], [UnitDefinition name:index]]];
        }
    }

    // join the list and show it
    NSString * listText = [names componentsJoinedByString:@"\n"];
    [self.unitListLabel setString:listText];

    self.playButton.visible = YES;
    self.unitListLabel.visible = YES;
    self.noUnitsLabel.visible = NO;
}


- (void) animateOutArmy {
    [self.unitListPaper stopAllActions];

    float angle = -50.0f + arc4random_uniform(100);
    [self.unitListPaper runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:1.0f position:ccp( 1600, 200  + arc4random_uniform(600))] rate:0.5f]];
    [self.unitListPaper runAction:[CCScaleTo actionWithDuration:2.0f scale:1.0f]];
    [self.unitListPaper runAction:[CCSequence actions:
                                   [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:1.0f angle:angle] rate:0.5f],
                                   [CCCallFunc actionWithTarget:self selector:@selector( armyAnimatedOut )],
                                   nil]];
}


- (void) animateInArmy {
    [self.unitListPaper stopAllActions];

    [self.unitListPaper runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.5f position:ccp(780, 300)] rate:0.5f]];
    [self.unitListPaper runAction:[CCScaleTo actionWithDuration:0.5f scale:1.0f]];
    [self.unitListPaper runAction:[CCSequence actions:
                                   [CCEaseIn actionWithAction:[CCRotateTo actionWithDuration:0.5f angle:2] rate:0.5f],
                                   nil]];
}


- (void) armyAnimatedOut {
    [self showArmy];
    [self animateInArmy];
}


//***************************************************************************************************************
#pragma mark - Online games delegate

- (void) loginOk {
    CCLOG( @"login ok" );

    // next up is the army selection
    [self animateNodesAwayAndShowScene:[Lobby node]];
}


- (void) connectionFailed {
    CCLOG( @"connection failed" );
    [self showErrorScreen:@"Connection to the server failed! Please try again later." backScene:[SelectArmy node]];
}


- (void) loginFailed:(NetworkLoginErrorReason)reason {
    if ( reason == kAlreadyLoggedInError ) {
        // already logged in then, not really an error
        CCLOG( @"we're already logged in, so just proceeding" );
        [self loginOk];
        return;
    }

    CCLOG( @"login failed, reason: %d", reason );

    // analytics
    [Answers logCustomEventWithName:@"Login failed"
                   customAttributes:@{ @"reason" : @(reason) } ];

    switch (reason) {
        case kInvalidProtocolError:
            [self showErrorScreen:@"Seems your game is outdated, please update from the App Store."];
            break;
        case kInvalidNameError:
            [self showErrorScreen:@"Invalid name! Please choose another name." backScene:[SelectArmy node]];
            break;
        case kAlreadyLoggedInError:
            [self showErrorScreen:@"Already logged in? This should never happen..." backScene:[SelectArmy node]];
            break;
        case kNameTakenError:
            [self showErrorScreen:@"The name has already been taken! Please choose another name." backScene:[SelectArmy node]];
            break;
        case kServerFullError:
            [self showErrorScreen:@"The server is full! Please try again later."];
            break;
        case kInvalidPasswordError:
            [self showErrorScreen:@"Failed to log in, this should never happen."];
            break;
    }
}


@end
