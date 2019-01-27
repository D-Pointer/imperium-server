
#import <Foundation/Foundation.h>

#import "Definitions.h"
#import "Unit.h"
#import "Objective.h"
#import "Clock.h"
#import "ScoreCounter.h"
#import "Player.h"
#import "PathFinder.h"
#import "TcpNetworkHandler.h"

@class Scenario;
@class GameLayer;
@class Engine;
@class LineOfSight;
@class HostedGame;
@class UdpNetworkHandler;
@class Army;
@class ParameterHandler;
@class Map;

@interface Globals : NSObject

@property (nonatomic, assign) int              campaignId;
@property (nonatomic, strong) Player *         player1;
@property (nonatomic, strong) Player *         player2;
@property (nonatomic, strong)  NSMutableArray *        units;
@property (nonatomic, strong)  NSMutableArray *        unitsPlayer1;
@property (nonatomic, strong)  NSMutableArray *        unitsPlayer2;
@property (nonatomic, strong)  NSMutableArray *        objectives;
@property (nonatomic, strong)  NSMutableArray *        organizations;
@property (nonatomic, strong)  NSMutableArray *        smoke;
@property (nonatomic, strong) Scenario *       scenario;
@property (nonatomic, strong) Map *            map;
@property (nonatomic, strong) Clock *          clock;
@property (nonatomic, strong) Engine *         engine;
@property (nonatomic, strong) LineOfSight *    lineOfSight;

@property (nonatomic, strong) ScoreCounter *   scores;
@property (nonatomic, strong) PathFinder *     pathFinder;

@property (nonatomic, strong) TcpNetworkHandler *  tcpConnection;
@property (nonatomic, strong) UdpNetworkHandler *  udpConnection;
@property (nonatomic, strong) ParameterHandler *   parameterHandler;

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
