
#import "Layer.h"
#import "TcpNetworkHandler.h"

@interface Wait : Layer <OnlineGamesDelegate>

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          infoPaper;

@end
