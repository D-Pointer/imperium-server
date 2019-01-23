
#import "GCDAsyncSocket.h"
#import "Definitions.h"
#import "HostedGame.h"
#import "UdpNetworkHandler.h"

@class Unit;
@class Mission;
@class Scenario;
@class HostedGame;
@class UdpPacket;

@protocol OnlineGamesDelegate <NSObject>

@optional
- (void) connectedOk;
- (void) connectionFailed;

- (void) loginOk;
- (void) loginFailed:(NetworkLoginErrorReason)reason;

- (void) playerCountUpdated:(int)count;

- (void) gameAnnounceOk;
- (void) gameAnnounceFailed;

- (void) gamesUpdated;
- (void) failedToJoinGame;

- (void) gameJoined:(HostedGame *)game;

- (void) unitsReceived;

- (void) gameCompleted;

- (void) gameEnded;

- (void) serverPongReceived:(double)milliseconds;
- (void) playerPongReceived:(double)milliseconds;

@end


@interface TcpNetworkHandler : NSObject <GCDAsyncSocketDelegate, UdpNetworkHandlerDelegate>

@property (nonatomic, strong)   NSString *       onlineName;
@property (nonatomic, readonly) NSMutableArray * games;
@property (nonatomic, strong)   NSMutableSet *   delegates;
@property (nonatomic, readonly) BOOL             isConnected;
@property (nonatomic, readonly) int              playerCount;

- (instancetype) init;

- (void) registerDelegate:(id<OnlineGamesDelegate>)delegate;
- (void) deregisterDelegate:(id<OnlineGamesDelegate>)delegate;

- (BOOL) connect;

- (void) disconnect;

- (void) sendKeepAlive;

- (void) loginWithName:(NSString *)name;

- (void) announceScenario:(Scenario *)scenario;

- (void) joinGame:(HostedGame *)game;

- (void) leaveGame;

- (void) sendUnits;

- (void) sendWind;

- (void) readyToStart;

// sends an "game over" packet
- (void) endGame;


@end
