#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "EnterName.h"
#import "Globals.h"
#import "SelectArmy.h"
#import "MainMenu.h"
#import "Utils.h"

@interface EnterName ()

@property (nonatomic, strong) UITextField *nameField;

@end

@implementation EnterName

@synthesize backButton;
@synthesize proceedButton;
@synthesize namePaper;
@synthesize connectingPaper;
@synthesize helpPaper;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"EnterName.ccb"];
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];
    [self createText:@"Connect" forButton:self.proceedButton includeDisabled:YES];
}


- (void) onEnter {
    [super onEnter];

    // we want to know when we're online or not
    [[Globals sharedInstance].tcpConnection registerDelegate:self];

    // position all nodes outside
    self.namePaper.position = ccp( 500, 1300 );
    self.namePaper.rotation = 50;
    self.namePaper.scale = 2.0f;

    self.helpPaper.position = ccp( 300, -200 );
    self.helpPaper.rotation = 50;
    self.helpPaper.scale = 2.0f;

    // the connecting paper is outside and stays outside
    self.connectingPaper.position = ccp( 1400, 400 );
    self.connectingPaper.rotation = 50;
    self.connectingPaper.scale = 2.0f;

    // animate in the name and help papers
    [self moveNode:self.namePaper toPos:ccp( 512, 400 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.namePaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.namePaper toAngle:0 inTime:0.5f atRate:0.5f];

    [self moveNode:self.helpPaper toPos:ccp( 160, 460 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.helpPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.helpPaper toAngle:-3 inTime:0.5f atRate:0.5f];

    // create the text field after the animations are done
    [[[CCDirector sharedDirector] scheduler] scheduleSelector:@selector( createTextField ) forTarget:self interval:0.5f repeat:0 delay:0 paused:NO];

    // animate in the connecting papee
    //[self moveNode:self.connectingPaper toPos:ccp(730, 230) inTime:0.5f atRate:1.5f];
    //[self scaleNode:self.connectingPaper toScale:1.0f inTime:0.5f];
    //[self rotateNode:self.connectingPaper toAngle:7 inTime:0.5f atRate:0.5f];

    // both papers are animatable
    [self addAnimatableNode:self.namePaper];
    [self addAnimatableNode:self.helpPaper];
}


- (void) onExit {
    [super onExit];
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) createTextField {
    // get the previous name
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // create the edit field
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake( 512 - 150, 320, 300, 50 )];
    self.nameField.delegate = self;
    self.nameField.textAlignment = NSTextAlignmentCenter;
    self.nameField.text = [defaults stringForKey:@"onlineName"];
    self.nameField.placeholder = @"Your name";
    self.nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nameField.font = [UIFont fontWithName:@"NuevaStd-BoldCond" size:28];

    // show the field
    [[[CCDirector sharedDirector] view] addSubview:self.nameField];

    // automatically show the keyboard if we have no name
    if (self.nameField.text.length < 3) {
        [self.nameField becomeFirstResponder];
    }

        // if the name is long enough then show the proceed button
    else {
        self.proceedButton.visible = YES;
    }
}


- (void) proceed {
    CCLOG( @"in" );
    Globals *globals = [Globals sharedInstance];

    [globals.audio playSound:kMenuButtonClicked];

    // disable the button to avoid multiple taps
    [self.proceedButton setIsEnabled:NO];

    // get the latest name
    NSString *name = self.nameField.text;

    // remove the name field
    if (self.nameField) {
        [self.nameField removeFromSuperview];
    }

    // animate in
    [self moveNode:self.connectingPaper toPos:ccp( 700, 185 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.connectingPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.connectingPaper toAngle:7 inTime:0.5f atRate:0.5f];

    // save the name immediately
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"onlineName"];
    [defaults synchronize];

    CCLOG( @"logging in to network server as: %@", name );
    [globals.tcpConnection loginWithName:name];
}


- (void) back {
    // remove the name field
    if (self.nameField) {
        [self.nameField removeFromSuperview];
    }

    // disable back button
    [self disableBackButton:self.backButton];

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayAndShowScene:[MainMenu node]];
}


//***************************************************************************************************************
#pragma mark - Online games delegate

- (void) loginOk {
    CCLOG( @"login ok" );

    // next up is the army selection
    [self animateNodesAwayAndShowScene:[SelectArmy node]];
}


- (void) connectionFailed {
    CCLOG( @"connection failed" );
    [self showErrorScreen:@"Connection to the server failed! Please try again later."];
}


- (void) loginFailed:(NetworkLoginErrorReason)reason {
    CCLOG( @"login failed, reason: %d", reason );

    switch (reason) {
        case kInvalidProtocolError:
            [self showErrorScreen:@"Seems your game is outdated, please update from the App Store."];
            break;
        case kInvalidNameError:
            [self showErrorScreen:@"Invalid name! Please choose another name." backScene:[EnterName node]];
            break;

        case kNameTakenError:
            [self showErrorScreen:@"The name has already been taken! Please choose another name." backScene:[EnterName node]];
            break;

        case kServerFullError:
            [self showErrorScreen:@"The server is full! Please try again later."];
            break;
    }
}

//- (void)registrationFailed {
//    CCLOG( @"registration failed" );
//
//    // remove the name field
//    if (self.nameField) {
//        [self.nameField removeFromSuperview];
//    }
//
//    // show an error and then back to the main menu
//    [self showErrorScreen:@"The name has already been taken! Please choose another name."];
//}


//***************************************************************************************************************
#pragma mark - Text field delegate

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // get the name
    Player *localPlayer = [Globals sharedInstance].localPlayer;

    // apply the changes to the name
    localPlayer.name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    // only allow the editing to end if we have enough content
    if (localPlayer.name == nil || localPlayer.name.length < 3) {
        CCLOG( @"too short name" );
        self.proceedButton.visible = NO;
    }
    else {
        // the name is ok
        self.proceedButton.visible = YES;
    }

    // allow all edits
    return YES;
}


- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    // only allow the editing to end if we have enough content
    if (textField.text == nil || textField.text.length < 3) {
        CCLOG( @"editing can not end yet" );
        self.proceedButton.visible = NO;
        return NO;
    }

    CCLOG( @"name is ok" );
    [self.nameField resignFirstResponder];

    self.proceedButton.visible = YES;

    // all is ok
    return YES;
}


- (void) textFieldDidEndEditing:(UITextField *)textField {
    CCLOG( @"in" );

}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    CCLOG( @"return pressed" );
    [self.nameField resignFirstResponder];
    return YES;
}


@end
