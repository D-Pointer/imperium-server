
#import <Foundation/Foundation.h>

#import "AppDelegate.h"
#import "Definitions.h"
#import "Selection.h"
#import "Unit.h"
#import "Objective.h"
#import "Clock.h"
#import "ScoreCounter.h"
#import "Player.h"
#import "Audio.h"
#import "PathFinder.h"
#import "ActionsMenu.h"
#import "TcpNetworkHandler.h"
#import "Settings.h"

@class Scenario;
@class AI;
@class MapLayer;
@class GameLayer;
@class Tutorial;
@class Engine;
@class Input;
@class LineOfSight;
@class HostedGame;
@class UdpNetworkHandler;
@class ScenarioScript;
@class GameCenter;
@class Army;
@class ParameterHandler;

@interface Globals : NSObject

@property (nonatomic, weak)   AppDelegate *    appDelegate;
@property (nonatomic, assign) int              campaignId;
@property (nonatomic, strong) Player *         player1;
@property (nonatomic, strong) Player *         player2;
@property (nonatomic, strong) Player *         localPlayer;
@property (nonatomic, assign) GameType         gameType;
@property (nonatomic, strong) CCArray *        units;
@property (nonatomic, weak)   CCArray *        localUnits;
@property (nonatomic, strong) CCArray *        unitsPlayer1;
@property (nonatomic, strong) CCArray *        unitsPlayer2;
@property (nonatomic, strong) CCArray *        objectives;
@property (nonatomic, strong) CCArray *        organizations;
@property (nonatomic, strong) Selection *      selection;
@property (nonatomic, strong) Scenario *       scenario;
@property (nonatomic, strong) ScenarioScript * scenarioScript;
@property (nonatomic, strong) Clock *          clock;
@property (nonatomic, strong) AI *             ai;
@property (nonatomic, strong) MapLayer *       mapLayer;
@property (nonatomic, weak)   GameLayer *      gameLayer;
@property (nonatomic, strong) Engine *         engine;
@property (nonatomic, strong) LineOfSight *    lineOfSight;
@property (nonatomic, strong) Input *          input;

@property (nonatomic, strong) ActionsMenu *    actionsMenu;

@property (nonatomic, strong) ScoreCounter *   scores;
@property (nonatomic, strong) Audio *          audio;
@property (nonatomic, strong) Tutorial *       tutorial;
@property (nonatomic, strong) PathFinder *     pathFinder;

// networking
@property (nonatomic, strong) GameCenter *         gameCenter;
@property (nonatomic, strong) TcpNetworkHandler *  tcpConnection;
@property (nonatomic, strong) UdpNetworkHandler *  udpConnection;
@property (nonatomic, strong) ParameterHandler *   parameterHandler;

// all available scenarios and a downloader
@property (nonatomic, strong) CCArray *            scenarios;
@property (nonatomic, strong) CCArray *            multiplayerScenarios;

// online data
@property (nonatomic, strong) HostedGame *         onlineGame;

// multiplayer data
@property (nonatomic, strong) NSArray *            armies;
@property (nonatomic, strong) Army *               currentArmy;

/**
 * Returns a singleton instance of the game data.
 **/
+ (Globals *) sharedInstance;

- (void) reset;

@end
