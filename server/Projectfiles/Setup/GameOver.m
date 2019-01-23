
#import <Crashlytics/Answers.h>
#import "CCBReader.h"

#import "GameOver.h"
#import "Globals.h"
#import "ScoreCounter.h"
#import "Scenario.h"
#import "SelectScenario.h"
#import "MainMenu.h"
#import "GameSerializer.h"
#import "Utils.h"


@implementation GameOver

@synthesize title;
@synthesize player1Name;
@synthesize player2Name;
@synthesize totalMen1;
@synthesize totalMen2;
@synthesize lostMen1;
@synthesize lostMen2;
@synthesize objectives1;
@synthesize objectives2;
@synthesize reason;
@synthesize paper;
@synthesize backButton;

+ (id) singlePlayerNode {
    Globals * globals = [Globals sharedInstance];

    GameOver * gameOver;

    // which player won?
    if ( globals.scenario.endCondition.winner == kPlayer1 ) {
        CCLOG( @"local player won" );
        gameOver = (GameOver *)[CCBReader nodeGraphFromFile:@"GameOverWon.ccb"];
    }
    else {
        CCLOG( @"local player lost" );
        gameOver = (GameOver *)[CCBReader nodeGraphFromFile:@"GameOverLost.ccb"];
    }

    // set up for single player
    [gameOver setupForSinglePlayer];

    // embed in a scene
    CCScene * scene = [CCScene new];
    [scene addChild:gameOver];
    return scene;
}


+ (id) multiPlayerNode {
    Globals * globals = [Globals sharedInstance];

    GameOver * gameOver;

    MultiplayerEndType endType = globals.onlineGame.endType;

    CCLOG( @"game: %@", globals.onlineGame );
    
    // which player won?
    if ( ( globals.localPlayer.playerId == kPlayer1 && endType == kPlayer2Destroyed ) ||
        ( globals.localPlayer.playerId == kPlayer2 && endType == kPlayer1Destroyed ) ) {
        CCLOG( @"local player won" );
        gameOver = (GameOver *)[CCBReader nodeGraphFromFile:@"GameOverWon.ccb"];
    }
    else if ( endType == kTimeOut ) {
        CCLOG( @"time out, so local player lost too" );
        gameOver = (GameOver *)[CCBReader nodeGraphFromFile:@"GameOverLost.ccb"];
    }
    else {
        CCLOG( @"local player lost" );
        gameOver = (GameOver *)[CCBReader nodeGraphFromFile:@"GameOverLost.ccb"];
    }

    // set up for multiplayer
    [gameOver setupForMultiplayer:endType];

    // embed in a scene
    CCScene * scene = [CCScene new];
    [scene addChild:gameOver];
    return scene;
}


- (void) didLoadFromCCB {
    Globals * globals = [Globals sharedInstance];

    ScoreCounter * scores = globals.scores;

    int tmpTotalMen1   = [scores getTotalMen:kPlayer1];
    int tmpTotalMen2   = [scores getTotalMen:kPlayer2];
    int tmpLostMen1    = [scores getLostMen:kPlayer1];
    int tmpLostMen2    = [scores getLostMen:kPlayer2];
    int tmpObjectives1 = [scores getObjectivesScore:kPlayer1];
    int tmpObjectives2 = [scores getObjectivesScore:kPlayer2];

    // should we notify the other player?
    if ( globals.gameType == kMultiplayerGame && globals.localPlayer.playerId == kPlayer1 ) {
        NSMutableData * data = [NSMutableData data];
        [data appendData:[NSMutableData dataWithBytes:&tmpTotalMen1 length: sizeof(int)]];
        [data appendData:[NSMutableData dataWithBytes:&tmpTotalMen2 length: sizeof(int)]];
        [data appendData:[NSMutableData dataWithBytes:&tmpLostMen1 length: sizeof(int)]];
        [data appendData:[NSMutableData dataWithBytes:&tmpLostMen2 length: sizeof(int)]];
        [data appendData:[NSMutableData dataWithBytes:&tmpObjectives1 length: sizeof(int)]];
        [data appendData:[NSMutableData dataWithBytes:&tmpObjectives2 length: sizeof(int)]];
    }

    // setup all labels
    [self.title       setString:globals.scenario.title];
    [self.totalMen1   setString:[NSString stringWithFormat:@"%d men", tmpTotalMen1]];
    [self.totalMen2   setString:[NSString stringWithFormat:@"%d men", tmpTotalMen2]];
    [self.lostMen1    setString:[NSString stringWithFormat:@"%d men", tmpLostMen1]];
    [self.lostMen2    setString:[NSString stringWithFormat:@"%d men", tmpLostMen2]];
    [self.objectives1 setString:[NSString stringWithFormat:@"%d",     tmpObjectives1]];
    [self.objectives2 setString:[NSString stringWithFormat:@"%d",     tmpObjectives2]];

    // set up the buttons
    [self createText:@"Ok" forButton:self.backButton];
}


- (void) setupForSinglePlayer {
    Globals * globals = [Globals sharedInstance];

    [self.player1Name setString:@"Ourland"];
    [self.player2Name setString:@"Perseuts" ];

    // the reason text can be long, so wrap it at 350 pixels
    [Utils showString:globals.scenario.endCondition.text onLabel:self.reason withMaxLength:350];

    // winning player
    PlayerId winningPlayer = globals.scenario.endCondition.winner;

    NSNumber * won;

    // stop the in game music and play a victory or defeat jingle
    [globals.audio stopMusic];
    if ( globals.localPlayer.playerId == winningPlayer ) {
        [globals.audio playMusic:kVictoryJingle];
        won = @YES;
    }
    else {
        [globals.audio playMusic:kDefeatJingle];
        won = @NO;
    }

    // analytics
    if (globals.scenario.scenarioType == kTutorial) {
        [Answers logLevelEnd:[NSString stringWithFormat:@"Tutorial %d", globals.scenario.scenarioId]
                       score:0
                     success:won
            customAttributes:@{ @"title" : globals.scenario.title,
                                @"reason" : globals.scenario.endCondition.text,
                                @"winner" : winningPlayer == kPlayer1 ? @"player 1" : @"player 2"
                                }];

        // all tutorials completed?
        if ( globals.scenario.scenarioId == 2 ) {
            [Answers logCustomEventWithName:@"Tutorials completed" customAttributes:nil];
        }
    }
    else {

        [Answers logLevelEnd:[NSString stringWithFormat:@"Campaign %d", globals.scenario.scenarioId]
                       score:0
                     success:won
            customAttributes:@{ @"title" : globals.scenario.title,
                                @"reason" : globals.scenario.endCondition.text,
                                @"winner" : winningPlayer == kPlayer1 ? @"player 1" : @"player 2"
                                }];
    }

    // at this point we can't have any saved game anymore
    [GameSerializer deleteSavedGame:[NSString stringWithFormat:sSaveFileNameSingle, [Globals sharedInstance].campaignId]];
}


- (void) setupForMultiplayer:(MultiplayerEndType)endReason {
    Globals * globals = [Globals sharedInstance];

    if ( globals.localPlayer.playerId == kPlayer1 ) {
        [self.player1Name setString:globals.localPlayer.name];
        [self.player2Name setString:globals.onlineGame.opponentName];
    }
    else {
        [self.player1Name setString:globals.onlineGame.opponentName];
        [self.player2Name setString:globals.localPlayer.name];
    }

    CCLOG( @"end type: %d", endReason );
    
    MusicType jingleType;
    NSString * endDescription;
    NSNumber * won;

    switch ( endReason ) {
        case kPlayer1Destroyed:
            if ( globals.localPlayer.playerId == kPlayer1 ) {
                jingleType = kDefeatJingle;
                won = @NO;
                endDescription = [NSString stringWithFormat:@"Defeat! Your army has been destroyed by %@", globals.onlineGame.opponentName];
            }
            else {
                jingleType = kVictoryJingle;
                won = @YES;
                endDescription = [NSString stringWithFormat:@"Victory! Your army has destroyed %@", globals.onlineGame.opponentName];
            }
            break;

        case kPlayer2Destroyed:
            if ( globals.localPlayer.playerId == kPlayer1 ) {
                jingleType = kVictoryJingle;
                won = @YES;
                endDescription = [NSString stringWithFormat:@"Victory! Your army has destroyed %@", globals.onlineGame.opponentName];
            }
            else {
                jingleType = kDefeatJingle;
                won = @NO;
                endDescription = [NSString stringWithFormat:@"Defeat! Your army has been destroyed by %@", globals.onlineGame.opponentName];
            }
            break;

        case kBothPlayersDestroyed:
            jingleType = kDefeatJingle;
            won = @NO;
            endDescription = @"Defeat! Both armies have been destroyed.";
            break;

        case kTimeOut:
            jingleType = kDefeatJingle;
            won = @NO;
            endDescription = @"Draw! Neither army has achieved a victory";
            break;
    }

    [globals.audio playMusic:jingleType];

    // the reason text can be long, so wrap it at 350 pixels
    [Utils showString:endDescription onLabel:self.reason withMaxLength:350];

    // analytics
    [Answers logLevelEnd:[NSString stringWithFormat:@"Online %d", globals.scenario.scenarioId]
                   score:0
                 success:won
        customAttributes:@{ @"title" : globals.scenario.title,
                            @"localPlayer" : globals.localPlayer.name,
                            @"remotePlayer" : globals.onlineGame.opponentName,
                            @"reason" : globals.scenario.endCondition.text,
                            }];
}


- (void) onEnter {
    [super onEnter];

    // position all nodes outside
    self.paper.position = ccp( 300, 1300 );
    self.paper.rotation = -20;
    self.paper.scale = 2.0f;

    // animate in them all
    [self moveNode:self.paper toPos:ccp(512, 340) inTime:0.5f atRate:1.5f];
    [self scaleNode:self.paper toScale:1.0f inTime:0.5f];
    [self rotateNode:self.paper toAngle:-2 inTime:0.5f atRate:2.0f];

    // these can be animated
    [self addAnimatableNode:self.paper];
}



- (void) back {
    // disable back button
    [self disableBackButton:self.backButton];

    [[Globals sharedInstance].audio playSound:kMenuButtonClicked];
    [self animateNodesAwayWithSelector:@selector(animationsDone)];
}


- (void) animationsDone {
    // play setup music again
    [[Globals sharedInstance].audio stopMusic];
    [[Globals sharedInstance].audio playMusic:kMenuMusic];

    GameType gameType = [Globals sharedInstance].gameType;

    // clear all data
    [[Globals sharedInstance] reset];

    if ( gameType == kMultiplayerGame ) {
        [[CCDirector sharedDirector] replaceScene:[MainMenu node]];
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[SelectScenario node]];
    }
}


@end
