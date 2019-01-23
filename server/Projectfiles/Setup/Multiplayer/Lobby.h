
#import "Layer.h"
#import "TcpNetworkHandler.h"

@class HostedGame;

@interface Lobby : Layer <OnlineGamesDelegate>

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * smallButton;
@property (nonatomic, strong) CCMenuItemImage * mediumButton;
@property (nonatomic, strong) CCMenuItemImage * largeButton;
@property (nonatomic, strong) CCNode *          gamesPaper;
@property (nonatomic, strong) CCNode *          scenariosPaper;
@property (nonatomic, strong) CCLabelBMFont *   noOpenGamesLabel;
@property (nonatomic, strong) CCLabelBMFont *   connectedPlayersLabel;

+ (void) setupGame:(HostedGame *)game;

@end
