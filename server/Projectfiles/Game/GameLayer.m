#import <Crashlytics/Answers.h>

#import "GameLayer.h"
#import "Unit.h"
#import "Clock.h"
#import "Panel.h"
#import "GameMenu.h"
#import "Globals.h"
#import "Tutorial.h"
#import "Scenario.h"
#import "GameMenuPopup.h"
#import "Input.h"
#import "StartPrompt.h"
#import "StartPromptOnline.h"
#import "AttackResult.h"
#import "Engine.h"
#import "SelectScenario.h"
#import "MainMenu.h"
#import "GameOver.h"
#import "PauseButton.h"

// DEBUG
#import "GameSerializer.h"

#import "RotateMission.h"
#import "MoveMission.h"
#import "RetreatMission.h"
#import "AdvanceMission.h"
#import "AssaultMission.h"
#import "FireMission.h"
#import "ScoutMission.h"

@interface GameLayer ()

@property (nonatomic, strong) PanZoomNode *panZoomNode;
@property (nonatomic, weak) MapLayer *mapLayer;
@property (nonatomic, strong) Panel *panel;
@property (nonatomic, strong) GameMenu *gameMenu;
@property (nonatomic, strong) PauseButton *pauseButton;
@property (nonatomic, strong) StartPromptOnline *onlineStartPrompt;

@end


@implementation GameLayer

+ (id) node {
    return [GameLayer new];
}


- (id) init {
    if ((self = [super init])) {
        Globals *globals = [Globals sharedInstance];

        // change to the in game music
        [globals.audio stopMusic];
        [globals.audio playMusic:kInGameMusic];

        // let everyone access us
        globals.gameLayer = self;

        // create the map layer if needed
        if (globals.mapLayer == nil) {
            globals.mapLayer = [MapLayer new];
            self.mapLayer = globals.mapLayer;
            self.mapLayer.position = ccp( 0, 0 );
        }
        else {
            self.mapLayer = globals.mapLayer;

            // does it already have a parent? it will have that if it was used earlier when deploying. we can not
            // add it to our panzoom node below if it has an old parent
            if (self.mapLayer.parent != nil) {
                [self.mapLayer removeFromParent];
            }
        }

        CGSize nodeSize = self.mapLayer.boundingBox.size;
        float panelHeight = 90;
        CGSize size = CGSizeMake( 1024, 768 - panelHeight );

        // create the pan/zoom node
        self.panZoomNode = [[PanZoomNode alloc] initWithSize:size];
        self.panZoomNode.delegate = self;
        self.panZoomNode.node = self.mapLayer;
        self.panZoomNode.maxScale = 2.2f;
        self.panZoomNode.minScale = MAX( size.width / nodeSize.width, size.height / nodeSize.height );
        self.panZoomNode.position = ccp( 0, panelHeight );
        [self addChild:self.panZoomNode];

        //CCLOG( @"pannable map size: %d %d", self.mapLayer.mapWidth, self.mapLayer.mapHeight );

        // panel
        self.panel = [Panel node];
        self.panel.position = ccp( 1024 * 0.5f, 50 );
        [self addChild:self.panel z:kHudZ];

        // when the game is manually quit
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( gameQuit ) name:sNotificationQuitGame object:nil];

        // when the game is about to end (time out, player lost etc)
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameAboutToEnd) name:NotificationGameAboutToEnd object:nil];

        // and when the game is backgrounded
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( gameBackgrounded ) name:sNotificationGameBackgrounded object:nil];

        // set up a tutorial if needed
        if (globals.scenario.scenarioType == kTutorial) {
            globals.tutorial = [[Tutorial alloc] init];

            CCLOG( @"starting the engine" );
            [globals.engine start];

            // analytics
            [Answers logLevelStart:[NSString stringWithFormat:@"Tutorial %d", globals.scenario.scenarioId]
                  customAttributes:@{ @"title" : globals.scenario.title }];
        }
        else if (globals.gameType == kMultiplayerGame) {
            // we have a multiplayer game, so set up the custom start prompt that waits for the game to start
            self.onlineStartPrompt = [StartPromptOnline node];
            self.onlineStartPrompt.position = ccp( 0, 0 );
            [self addChild:self.onlineStartPrompt z:kStartPromptZ];

            // we're now a delegate for the network stuff
            [globals.tcpConnection registerDelegate:self];

            // analytics
            [Answers logLevelStart:[NSString stringWithFormat:@"Online %d", globals.scenario.scenarioId]
                  customAttributes:@{ @"title" : globals.scenario.title,
                                      @"localPlayer" : globals.localPlayer.name,
                                      @"remotePlayer" : globals.onlineGame.opponentName }];
        }
        else {
            // single player scenario, start the game or show a start prompt
            StartPrompt *prompt = [StartPrompt node];
            prompt.position = ccp( 0, 0 );
            [self addChild:prompt z:kStartPromptZ];

            // analytics
            [Answers logLevelStart:[NSString stringWithFormat:@"Campaign %d", globals.scenario.scenarioId]
                  customAttributes:@{ @"title" : globals.scenario.title }];
        }

        // pausing is only for single player games as we can't pause online games
        if (globals.gameType == kSinglePlayerGame) {
            self.pauseButton = [PauseButton new];
            self.pauseButton.position = ccp( 1024 - 35, 768 - 35 );
            [self addChild:self.pauseButton z:kHudZ];
        }

        // common components

        // game menu
        self.gameMenu = [GameMenu new];
        self.gameMenu.position = ccp( 35, 768 - 35 );
        [self addChild:self.gameMenu z:kHudZ];

        // actions menu
        ActionsMenu *actionsMenu = [ActionsMenu new];
        actionsMenu.position = ccp( 0, 0 );
        [self addChild:actionsMenu z:kActionsMenuZ];
        globals.actionsMenu = actionsMenu;
    }

    return self;
}


- (void) dealloc {
    CCLOG( @"in" );
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // no longer a network delegate
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) onExit {
    [super onExit];

    // no longer a network delegate
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];
}


- (void) reset {
    CCLOG( @"in" );

    Globals * globals = [Globals sharedInstance];

    // cleanup
    [self.panel removeFromParentAndCleanup:YES];
    self.panel = nil;
    [self.gameMenu removeFromParentAndCleanup:YES];
    self.gameMenu = nil;

    // clean up the map layer
    self.panZoomNode.node = nil;

    // we're no delegate anymore
    self.panZoomNode.delegate = nil;
    [self.panZoomNode removeFromParentAndCleanup:YES];

    // map layer is also stored globally
    [self.mapLayer reset];
    self.mapLayer = nil;
    globals.mapLayer = nil;

    [globals.clock removeFromParentAndCleanup:YES];
    globals.clock = nil;

    [globals.tcpConnection deregisterDelegate:self];

    // leave the current game
    if ( globals.gameType == kMultiplayerGame) {
        [globals.tcpConnection leaveGame];
    }

    // the UDP socket is disconnected when we return to the main menu
}


- (CGRect) visibleMapRect {
    return self.panZoomNode.visibleRect;
}


- (CGPoint) panOffset {
    return ccpNeg( self.panZoomNode.panOffset );
}


- (void) gameAboutToEnd {
    // create the game over scene
    if ([Globals sharedInstance].gameType == kSinglePlayerGame) {
        [[CCDirector sharedDirector] replaceScene:[GameOver singlePlayerNode]];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[GameOver multiPlayerNode]];
    }
}


- (void) gameQuit {
    CCLOG( @"in" );

    // play setup music again
    [[Globals sharedInstance].audio stopMusic];
    [[Globals sharedInstance].audio playMusic:kMenuMusic];

    // clean up
    [[Globals sharedInstance] reset];

    //[self reset];

    // get rid of the game layer
    if ([Globals sharedInstance].gameType == kSinglePlayerGame) {
        [[CCDirector sharedDirector] replaceScene:[SelectScenario node]];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[MainMenu node]];
    }
}


- (void) gameBackgrounded {
    CCLOG( @"in" );

    // do not save the tutorial
    if ([Globals sharedInstance].tutorial == nil) {
        // no tutorial, what type of game? use different names per type
        switch ([Globals sharedInstance].gameType) {
            case kSinglePlayerGame:
                [GameSerializer saveGame:[NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId]];
                break;
            case kMultiplayerGame:
                [GameSerializer saveGame:sSaveFileNameMulti];
                break;
        }

        CCLOG( @"saved game" );
    }
}


- (void) showGameMenuPopup {
    CCLOG( @"in" );

    GameMenuPopup *popup = [GameMenuPopup node];
    [self addChild:popup z:kGameMenuZ];

    // pause the game (if possible)
    [[Globals sharedInstance].engine pause];
}


- (void) centerMapOn:(Unit *)unit {
    CCLOG(@"centering on unit %@", unit );
    [self.panZoomNode centerOn:unit.position];
}


- (CGPoint) convertMapCoordinateToWorld:(CGPoint)pos {
    return [self.panZoomNode.node convertToWorldSpace:pos];
}


- (void) startOnlineGame {
    if (self.onlineStartPrompt) {
        CCLOG( @"disposing the online start prompt" );
        [self.onlineStartPrompt removeFromParentAndCleanup:YES];
        self.onlineStartPrompt = nil;
    }
}


- (void) updateArrows {
    CGRect visible = [self visibleMapRect];
    CGPoint center = ccp( CGRectGetMidX( visible ), CGRectGetMidY( visible ) );

    const int panelHeight = 90;
    const int margin = 20;

    // check all units, both own and enemy
    for ( Unit * unit in [Globals sharedInstance].units ) {
        // skip the units that are visible
        if ( CGRectContainsPoint( visible, unit.position ) ) {
            unit.offmapArrow.visible = NO;
            continue;
        }

        // set up tghe arrow sprite if not yet used
        if ( unit.offmapArrow == nil ) {
            unit.offmapArrow = [CCSprite spriteWithSpriteFrameName:unit.owner == kPlayer1 ? @"OffmapArrow1.png" : @"OffmapArrow2.png"];
            [self addChild:unit.offmapArrow z:kOffmapArrowZ];
        }

        unit.offmapArrow.visible = YES;

        // arrow positions that keeps it on the edge of the visible rect
        float arrowX = clampf( unit.position.x, visible.origin.x, visible.origin.x + visible.size.width );
        float arrowY = clampf( unit.position.y, visible.origin.y, visible.origin.y + visible.size.height );

        // map the visible rect map coordinates to our game layer coordinates
        arrowX = margin + (arrowX - visible.origin.x ) / visible.size.width * ( 1024 - 2 * margin );
        arrowY = panelHeight + margin + ( arrowY - visible.origin.y ) / visible.size.height * (768 - panelHeight - 2 * margin );
        unit.offmapArrow.position = ccp( arrowX, arrowY );

        // angle from the center to the unit so that the arrow can be rotated
        float angle = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub( unit.position, center ), ccp(0, 1) ) );
        if ( angle < 0 ) {
            angle += 360;
        }

        unit.offmapArrow.rotation = angle;
    }
}


// ---------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Online game Delegate

- (void) gameCompleted {
    CCLOG( @"in" );
    [[CCDirector sharedDirector] replaceScene:[GameOver multiPlayerNode]];
}


- (void) gameEnded {
    // no longer a network delegate
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];

    [self showErrorScreen:@"Your opponent seems to have dropped out of the game. Game progress is lost."];
}


- (void) connectionFailed {
    CCLOG( @"connection failed" );

    // no longer a network delegate
    [[Globals sharedInstance].tcpConnection deregisterDelegate:self];

    [self showErrorScreen:@"Connection to the server broken! Game progress is lost. Please try again later."];
}


- (void) serverPongReceived:(double)milliseconds {
    [self.panel showServerPing:milliseconds];
}


// ---------------------------------------------------------------------------------------------------------------------------------------------------
#pragma mark - Pan Zoom Node Delegate

- (void) node:(CCNode *)node tappedAt:(CGPoint)pos {
    Globals *globals = [Globals sharedInstance];

    // check if a tutorial handles the tap
    if (globals.tutorial && [globals.tutorial checkTap:pos]) {
        return;
    }

    CCLOG( @"tapped: %.0f %.0f", pos.x, pos.y );

    // possible clicked unit
    Unit *clicked_unit = [self.mapLayer getUnitAt:pos];

    // own unit or clicked a visible unit?
    if (clicked_unit && (clicked_unit.owner == globals.localPlayer.playerId || clicked_unit.visible)) {
        [globals.input handleClickedUnit:clicked_unit];
        return;
    }

    // possible clicked objective
    Objective *clicked_objective = [self.mapLayer getObjectiveAt:pos];

    // any clicked objective?
    if (clicked_objective) {
        [globals.input handleClickedObjective:clicked_objective];
        return;
    }

    // clicked terrain or a unit that was not seen
    [globals.input handleClickedPos:pos];
}


- (void) pannedNode:(CCNode *)node {
    CCLOG( @"panned" );
    [self updateArrows];
}


- (void) node:(CCNode *)node scaledTo:(CGFloat)scale {
    // the map layer has now been scaled, set up an inverse scale for the attack results that
    // are currently visible. this makes them have the same size regardless of the scale factor
    for (Unit *unit in [Globals sharedInstance].units) {
        if (unit.attackResult) {
            unit.attackResult.scale = 1.0f / scale;
        }
    }

    [self updateArrows];
}


- (BOOL) shouldStartDragForNode:(CCNode *)node atPos:(CGPoint)pos {
    CCLOG( @"in" );

    Globals *globals = [Globals sharedInstance];

    // possible clicked unit
    Unit *pressedUnit = [self.mapLayer getUnitAt:pos];

    // do we have a selected unit that is ours?
    Unit *selected = globals.selection.selectedUnit;
    if (selected && selected.owner == globals.localPlayer.playerId) {
        // can the unit perform any actions at all, or is it meleeing/disorganized?
        if (![selected canBeGivenMissions]) {
            // no missions, so no dragging either
            return NO;
        }

        // new selection?
        if ([Globals sharedInstance].selection.selectedUnit != pressedUnit) {
            // clicked an own unit, make it the new selected unit
            return NO;
        }

        CCLOG( @"pressing own unit: %@", selected );
        [globals.input handleDragStartForUnit:selected];

        return YES;
    }

    return NO;
}


- (BOOL) node:(CCNode *)node draggedTo:(CGPoint)pos {
    Globals *globals = [Globals sharedInstance];

    // possible clicked unit
    Unit *draggedUnit = globals.selection.selectedUnit;

    CCLOG( @"dragging to %.0f, %.0f", pos.x, pos.y );

    // own unit pressed?
    if (draggedUnit && draggedUnit.owner == globals.localPlayer.playerId) {
        // own unit
        return [globals.input handleDragForUnit:draggedUnit toPos:pos];
    }

    // we're done with this drag
    return NO;
}


- (void) dragEndedForNode:(CCNode *)node {
    Globals *globals = [Globals sharedInstance];

    // possible clicked unit
    Unit *draggedUnit = globals.selection.selectedUnit;

    CCLOG( @"dragging done" );

    // own unit pressed?
    if (draggedUnit && draggedUnit.owner == [Globals sharedInstance].localPlayer.playerId) {
        // own unit, dragging is done
        [globals.input handleDragEndForUnit:draggedUnit];
    }
}


@end
