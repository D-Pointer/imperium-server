
#import "GCDAsyncSocket.h"

#import "CCBReader.h"

#import "LoadEditor.h"
#import "Globals.h"
#import "MapReader.h"
#import "Scenario.h"
#import "SelectScenario.h"
#import "GameLayer.h"
#import "LineOfSight.h"

@interface LoadEditor ()

@property (nonatomic, strong) UITextField *     ipTextField;
@property (nonatomic, strong) GCDAsyncSocket *  socket;
@property (nonatomic, strong) NSMutableString * scenarioData;

@end


@implementation LoadEditor

@synthesize paper;
@synthesize backButton;
@synthesize status;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"LoadEditor.ccb"];
}


- (instancetype) init {
    self = [super init];
    if (self) {
        self.socket = nil;
    }
    
    return self;
}


- (void) onEnter {
    [super onEnter];

    self.ipTextField = [[UITextField alloc] initWithFrame:CGRectMake(450, 280, 200, 90)];
    self.ipTextField.textColor = [UIColor darkTextColor];
    self.ipTextField.placeholder = @"IP address";
    self.ipTextField.keyboardType = UIKeyboardTypeDecimalPad;
    [self.ipTextField setDelegate:self];

    // find the last used IP
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * lastIp = [defaults stringForKey:@"editorIp"];
    if ( lastIp == nil ) {
        lastIp = @"";
    }

    [self.ipTextField setText:lastIp];
    [[[CCDirector sharedDirector] view] addSubview:self.ipTextField];
    [self.ipTextField becomeFirstResponder];
    
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) back {
    if ( self.ipTextField ) {
        [self.ipTextField resignFirstResponder];
    }

    // disable back button
    [self disableBackButton:self.backButton];

    [[CCDirector sharedDirector] pushScene:[SelectScenario node]];
}


- (BOOL) textFieldShouldReturn:(UITextField*)textField {
    // terminate editing
    [textField resignFirstResponder];
    return YES;
}


- (void) textFieldDidEndEditing:(UITextField*)textField {
    if ( textField != self.ipTextField) {
        return;
    }

    [self.ipTextField endEditing:YES];

    // get the real text
    NSString *ip = self.ipTextField.text;
    CCLOG( @"IP: %@", ip );

    // save the IP in defaults too
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:ip forKey:@"editorIp"];
    [defaults synchronize];

    // create the socket the first time
    if ( ! self.socket ) {
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSError *error = nil;
    if ( ! [self.socket connectToHost:ip onPort:45001 error:&error] ) {
        CCLOG( @"error connecting to: %@, error: %@", ip, error);
        return;
    }

    // create a new data container
    self.scenarioData = [NSMutableString new];

    // read data with a 10s timeout
    [self.socket readDataWithTimeout:10 tag:0];

    // show a status
    self.status.visible = YES;
    [self.status setString:@"Loading scenario..."];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Cocoa Async Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    CCLOG( @"connected ok to %@:%d", host, port );
}


- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    CCLOG( @"socket:%p didReadData:withTag: %ld", sock, tag);
    CCLOG( @"bytes: %lu", (unsigned long)data.length );

    // convert to a string
    NSString * scenarioData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // append internally
    [self.scenarioData appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

    // did we get the final "end"?
    if ( ! [self.scenarioData containsString:@"\nend\n"] && ! [self.scenarioData containsString:@"\r\nend\r\n"] ) {
        // read more data with a 10s timeout
        [self.socket readDataWithTimeout:10 tag:0];
        return;
    }

    // found the end
    CCLOG( @"end found" );
}


- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    CCLOG(@"disconnected, error: %@", error);

    CCLOG( @"total bytes: %lu", (unsigned long)self.scenarioData.length );

    // filename to save to
    NSString * filename = [NSString stringWithFormat:@"%@/%@/editor.map", [[NSBundle mainBundle] bundlePath], @"Scenarios"];

    // and save it
    NSError * saveError = nil;
    if ( ! [self.scenarioData writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:&saveError] ) {
        CCLOG( @"failed to save scenario to file: %@, error: %@", filename, error );
        [self.status setString:@"Failed to read scenario"];
        return;
    }

    Globals * globals = [Globals sharedInstance];

    // parse the meta data and create the scenario
    globals.scenario = [[MapReader new] parseScenarioMetaData:filename];
    NSAssert( globals.scenario, @"invalid scenario" );

    // add to the main set of scenarios
    [[Globals sharedInstance].scenarios addObject:globals.scenario];

    // the players must be set before the game layer is set up and the scenario parsed
    if ( globals.gameType == kSinglePlayerGame ) {
        globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
        globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kAIPlayer];
    }
    else {
        globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
        globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kNetworkPlayer];
    }

    globals.localPlayer = globals.player1;

    // create the real game scene
    [[CCDirector sharedDirector] replaceScene:[GameLayer node]];

    // load the map
    [[MapReader new] completeScenario:globals.scenario];

    // setup the scores
    //[globals.scores setup];

    // set the objective owners
    [Objective updateOwnerForAllObjectives];

    // initial line of sight update for the current player
    globals.lineOfSight = [LineOfSight new];
    [globals.lineOfSight update];

    // get rid of the text field
    [self.ipTextField removeFromSuperview];
    self.ipTextField = nil;

    // now we will be replaced by the game layer as set above
}

@end
