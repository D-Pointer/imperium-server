#import "CCBReader.h"

#import "Lobby.h"
#import "Globals.h"
#import "MapReader.h"
#import "HostGame.h"
#import "ScenarioScript.h"
#import "GameLayer.h"
#import "LineOfSight.h"
#import "Army.h"
#import "SelectArmy.h"
#import "HostedGame.h"
#import "Scenario.h"
#import "Utils.h"
#import "ResourceHandler.h"

const NSInteger zoomActionTag = 0xff;

@interface HostedGameMenuItem : CCMenuItem {
    float originalScale;
}

@property (nonatomic, strong) HostedGame *game;

- (instancetype) initWithGame:(HostedGame *)game scenario:(Scenario *)scenario target:(id)target selector:(SEL)selector;

@end


@implementation HostedGameMenuItem

- (instancetype) initWithGame:(HostedGame *)game scenario:(Scenario *)scenario target:(id)target selector:(SEL)selector {
    self = [super initWithTarget:target selector:selector];
    if (self) {
        self.game = game;

        // create the the label
        CCLabelBMFont *nameLabel = [CCLabelBMFont labelWithString:scenario.title fntFile:@"SetupFont.fnt"];
        nameLabel.anchorPoint = ccp( 0, 0 );
        nameLabel.position = ccp( 0, 20 );

        CCLabelBMFont *playerLabel = [CCLabelBMFont labelWithString:game.opponentName fntFile:@"SetupFont2.fnt"];
        playerLabel.position = ccp( 0, 0 );
        playerLabel.anchorPoint = ccp( 0, 0 );

        NSString *battleSize;
        switch (scenario.battleSize) {
            case kSmallBattle:
                battleSize = @"small map";
                break;
            case kMediumBattle:
                battleSize = @"medium map";
                break;
            case kLargeBattle:
                battleSize = @"large map";
                break;
            case kNotIncluded:
                battleSize = @"unknown map";
                break;
        }

        CCLabelBMFont *sizeLabel = [CCLabelBMFont labelWithString:battleSize fntFile:@"SetupFont2.fnt"];
        sizeLabel.position = ccp( 330, 0 );
        sizeLabel.anchorPoint = ccp( 1, 0 );

        [self addChild:nameLabel];
        [self addChild:playerLabel];
        [self addChild:sizeLabel];
        self.contentSize = CGSizeMake( 330, 20 + nameLabel.contentSize.height );

        self.anchorPoint = ccp( 0, 0.5f );
        self.userObject = game;
    }

    return self;
}


- (void) selected {
    if (_isEnabled) {
        [super selected];

        CCAction *action = [self getActionByTag:zoomActionTag];
        if (action)
            [self stopAction:action];
        else
            originalScale = self.scale;

        CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:originalScale * 1.1f];
        zoomAction.tag = zoomActionTag;
        [self runAction:zoomAction];
    }
}

- (void) unselected {
    if (_isEnabled) {
        [super unselected];
        [self stopActionByTag:zoomActionTag];
        CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:originalScale];
        zoomAction.tag = zoomActionTag;
        [self runAction:zoomAction];
    }
}

@end


@interface Lobby ()

@property (nonatomic, strong) CCMenu *gamesMenu;
@property (nonatomic, strong) CCMenu *scenariosMenu;
@property (nonatomic, strong) HostedGame *joiningGame;

@end


@implementation Lobby

@synthesize backButton;
@synthesize smallButton;
@synthesize mediumButton;
@synthesize largeButton;
@synthesize gamesPaper;
@synthesize scenariosPaper;
@synthesize noOpenGamesLabel;
@synthesize connectedPlayersLabel;

+ (id) node {
    return [CCBReader sceneWithNodeGraphFromFile:@"Lobby.ccb"];
}


- (void) didLoadFromCCB {
    // set up the buttons
    [self createText:@"Back" forButton:self.backButton];

    [Utils createText:@"Small" withYOffset:0 forButton:self.smallButton withFont:@"ButtonFontSmall.fnt" includeDisabled:NO];
    [Utils createText:@"Medium" withYOffset:0 forButton:self.mediumButton withFont:@"ButtonFontSmall.fnt" includeDisabled:NO];
    [Utils createText:@"Large" withYOffset:0 forButton:self.largeButton withFont:@"ButtonFontSmall.fnt" includeDisabled:NO];

    // no game we're joining yet
    self.joiningGame = nil;

    Globals *globals = [Globals sharedInstance];

    // do we need to parse the multiplayer scenarios?
    if (globals.multiplayerScenarios.count == 0) {
        // find all the scenarios
        // scenario path
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *scenarioDir = [[paths objectAtIndex:0] stringByAppendingString:@"/Scenarios/Multiplayer"];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *dirContents = [manager contentsOfDirectoryAtPath:scenarioDir error:nil];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.map'"];
        NSArray *scenarioList = [dirContents filteredArrayUsingPredicate:filter];

        for (NSString *path in scenarioList) {
            // parse the meta data
            Scenario *scenario = [[MapReader new] parseScenarioMetaData:[NSString stringWithFormat:@"%@/%@", scenarioDir, path]];
            NSAssert( scenario, @"invalid scenario" );
            [globals.multiplayerScenarios addObject:scenario];
        }

        CCLOG( @"parsed metadata for %lu multiplayer scenarios", (unsigned long) globals.multiplayerScenarios.count );
    }

    // show the small scenarios by default
    [self showScenarios:self.smallButton];
}


- (void) onEnter {
    [super onEnter];

    // start fetching the games
    [[Globals sharedInstance].tcpConnection registerDelegate:self];

    // update the games once
    [self gamesUpdated];

    // position all nodes outside
    self.gamesPaper.position = ccp( -300, 300 );
    self.gamesPaper.rotation = -50;
    self.gamesPaper.scale = 2.0f;

    self.scenariosPaper.position = ccp( 1200, 400 );
    self.scenariosPaper.rotation = 40;
    self.scenariosPaper.scale = 2.0f;

    // animate in
    [self moveNode:self.gamesPaper toPos:ccp( 370, 320 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.gamesPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.gamesPaper toAngle:-1.7 inTime:0.5f atRate:0.5f];

    [self moveNode:self.scenariosPaper toPos:ccp( 790, 310 ) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.scenariosPaper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.scenariosPaper toAngle:1.1 inTime:0.5f atRate:1.5f];

    // these can be animated
    [self addAnimatableNode:self.gamesPaper];
    [self addAnimatableNode:self.scenariosPaper];

    // make sure the player count label is updated
    [self.connectedPlayersLabel setString:[NSString stringWithFormat:@"Connected players: %d", [Globals sharedInstance].tcpConnection.playerCount]];

    // fade in the Back button
    [self fadeNode:self.backButton fromAlpha:0 toAlpha:255 afterDelay:0 inTime:1];
}


- (void) onExit {
    [super onExit];
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) showScenarios:(id)sender {
    BattleSizeType size;
    if ( sender == self.smallButton ) {
        size = kSmallBattle;
    }
    else if ( sender == self.mediumButton ) {
        size = kMediumBattle;
    }
    else if ( sender == self.largeButton ) {
        size = kLargeBattle;
    }
    else {
        NSAssert( NO, @"invalid button, not a size button" );
    }

    Globals *globals = [Globals sharedInstance];

    NSMutableArray *scenarioItems = [NSMutableArray new];
    int x = 30;
    int y = 370;

    // create menu items for them all
    for (Scenario *scenario in globals.multiplayerScenarios) {
        if ( scenario.battleSize == size ) {
            CCLabelBMFont *label = [CCLabelBMFont labelWithString:scenario.title fntFile:@"SetupFont.fnt"];
            CCMenuItemLabel *menuItem = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector( announceScenario: )];
            menuItem.anchorPoint = ccp( 0, 0.5f );
            menuItem.position = ccp( x, y );
            menuItem.userObject = scenario;
            [scenarioItems addObject:menuItem];

            // next item is a bit below
            y -= 30;
        }
    }

    // clean up any old menu
    if ( self.scenariosMenu ) {
        [self.scenariosMenu removeFromParentAndCleanup:YES];
        self.scenariosMenu = nil;
    }

    // create an empty menu
    self.scenariosMenu = [CCMenu menuWithArray:scenarioItems];
    self.scenariosMenu.position = ccp( 0, 0 );
    [self.scenariosPaper addChild:self.scenariosMenu];
}


- (void) announceScenario:(id)sender {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    Scenario *selected = ((CCMenuItemLabel *) sender).userObject;
    [self animateNodesAwayAndShowScene:[HostGame nodeWithScenario:selected]];

    // disable and fade out back button
    [self disableBackButton:self.backButton];
}


- (void) joinGame:(id)sender {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    HostedGame *game = ((CCMenuItemLabel *) sender).userObject;

    // do we already have a game?
    if (self.joiningGame) {
        CCLOG( @"already joining %@, can not join %@", self.joiningGame, game );
        return;
    }

    self.joiningGame = game;

    NSAssert( self.joiningGame, @"nil game" );
    CCLOG( @"selected game: %@", self.joiningGame );

    // try to join it
    [[Globals sharedInstance].tcpConnection joinGame:self.joiningGame];
}


- (void) back {
    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];

    // disable back button
    [self disableBackButton:self.backButton];

    [self animateNodesAwayAndShowScene:[SelectArmy node]];
}


//***************************************************************************************************************
#pragma mark - Online Games Delegate

- (void) playerCountUpdated:(int)count {
    CCLOG( @"current player count: %d", count );
    [self.connectedPlayersLabel setString:[NSString stringWithFormat:@"Connected players: %d", count]];
}


- (void) gamesUpdated {
    // can get called by ourselves as well as an online delegate

    // clear all old labels
    if (self.gamesMenu) {
        [self.gamesMenu removeAllChildren];
        [self.gamesMenu removeFromParent];
        self.gamesMenu = nil;
    }

    if ([Globals sharedInstance].tcpConnection.games == nil || [Globals sharedInstance].tcpConnection.games.count == 0) {
        self.noOpenGamesLabel.visible = YES;
        CCLOG( @"no open games" );
        return;
    }

    // we have games
    self.noOpenGamesLabel.visible = NO;

    NSMutableArray *gameLabels = [NSMutableArray new];

    CCLOG( @"games: %lu", (unsigned long)[Globals sharedInstance].tcpConnection.games.count );

    int x = 30;
    int y = 400;
    for (HostedGame *game in [Globals sharedInstance].tcpConnection.games) {
        CCLOG( @"adding game: %@", game );

        // find the scenario the game refers to
        Scenario *hostedScenario = nil;
        for (Scenario *scenario in [Globals sharedInstance].multiplayerScenarios) {
            if (scenario.scenarioId == game.scenarioId) {
                hostedScenario = scenario;
            }
        }

        if (!hostedScenario) {
            CCLOG( @"did not find scenario %d", game.scenarioId );
            continue;
        }

        // a menu item for the game
        HostedGameMenuItem *menuItem = [[HostedGameMenuItem alloc] initWithGame:game scenario:hostedScenario
                                                                         target:self selector:@selector( joinGame: )];
        menuItem.position = ccp( x, y );
        [gameLabels addObject:menuItem];

        // next item is a bit below
        y -= 45;
    }

    // create an empty menu
    self.gamesMenu = [CCMenu menuWithArray:gameLabels];
    self.gamesMenu.position = ccp( 0, 0 );
    [self.gamesPaper addChild:self.gamesMenu];

    // make sure that the game we're joining is still here
    if (self.joiningGame) {
        BOOL found = NO;
        for (HostedGame *game in [Globals sharedInstance].tcpConnection.games) {
            if (game.gameId == self.joiningGame.gameId) {
                found = YES;
            }
        }

        if (!found) {
            self.joiningGame = nil;
            CCLOG( @"TODO: show error that the game we wanted to join is no longer valid" );
        }
    }
}


- (void) failedToJoinGame {
    [self showErrorScreen:@"Game was removed or started by other players, please select another game." backScene:[Lobby node]];
}


- (void) gameJoined:(HostedGame *)game {
    [Lobby setupGame:game];
}


+ (void) setupGame:(HostedGame *)game {
    CCLOG( @"game is ready: %@", game );
    Globals *globals = [Globals sharedInstance];

    // first find the scenario
    globals.scenario = nil;
    for (Scenario *scenario in globals.multiplayerScenarios) {
        if (scenario.scenarioId == game.scenarioId) {
            // found it
            globals.scenario = scenario;
            break;
        }
    }

    if (globals.scenario == nil) {
        // show an error scene
        //[self showErrorScreen:@"Game was removed or started by other players, please select another game." backScene:[Lobby node]];
        CCLOG( @"did not find scenario with id: %d!", game.scenarioId );
        return;
    }

    // set up players for a multiplayer game
    globals.gameType = kMultiplayerGame;
    if (game.localPlayerId == kPlayer1) {
        globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kLocalPlayer];
        globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kNetworkPlayer];
        globals.localPlayer = globals.player1;
        globals.localUnits = globals.unitsPlayer1;
        CCLOG( @"we're player 1" );
    }
    else {
        globals.player1 = [[Player alloc] initWithId:kPlayer1 type:kNetworkPlayer];
        globals.player2 = [[Player alloc] initWithId:kPlayer2 type:kLocalPlayer];
        globals.localPlayer = globals.player2;
        globals.localUnits = globals.unitsPlayer2;
        CCLOG( @"we're player 2" );
    }

    // save the online name too
    globals.localPlayer.name = globals.tcpConnection.onlineName;

    // save the game for later too
    globals.onlineGame = game;

    // create the real game scene
    [[CCDirector sharedDirector] replaceScene:[GameLayer node]];

    // load the map
    [[MapReader new] completeScenario:globals.scenario];

    // create the units for the local player
    NSAssert( globals.currentArmy, @"no current army" );
    [globals.currentArmy createUnitsForPlayer:game.localPlayerId];

    CCLOG( @"sending units to other player" );
    [globals.tcpConnection sendUnits];

    // if we're player 1 then our wind is what we'll use
    if (game.localPlayerId == kPlayer1) {
        CCLOG( @"sending wind to other player" );
        [globals.tcpConnection sendWind];
    }

    // set the objective owners
    [Objective updateOwnerForAllObjectives];

    // NOTE: line of sight is not updated here as we have no enemy units yet and the LOS data is initialized
    // once and needs both player's units. So it's done in TcpNetworkHandler.handleSetupUnits when we receive
    // the enemies

    // select and center the map on the first unit
    globals.selection.selectedUnit = [globals.localUnits objectAtIndex:0];
    [globals.gameLayer centerMapOn:globals.selection.selectedUnit];

    // setup the scenario script
    [globals.scenarioScript setupForScenario:globals.scenario];
}

@end
