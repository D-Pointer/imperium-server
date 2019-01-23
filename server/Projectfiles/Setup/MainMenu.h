
#import "cocos2d.h"
#import "Layer.h"
#import "TcpNetworkHandler.h"
#import "GameCenter.h"

@interface MainMenu : Layer <OnlineGamesDelegate, GameCenterDelegate>

@property (nonatomic, strong) CCNode *          playPaper;
@property (nonatomic, strong) CCNode *          miscPaper;
@property (nonatomic, strong) CCMenuItemImage * singleButton;
@property (nonatomic, strong) CCMenuItemImage * multiButton;
@property (nonatomic, strong) CCMenuItemImage * helpButton;
@property (nonatomic, strong) CCMenuItemImage * aboutButton;
@property (nonatomic, strong) CCMenuItemImage * sfxButton;
@property (nonatomic, strong) CCMenuItemImage * musicButton;

@end
