
#import "Layer.h"
#import "TcpNetworkHandler.h"

@interface EnterName : Layer <OnlineGamesDelegate, UITextFieldDelegate>

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * proceedButton;
@property (nonatomic, strong) CCNode *          namePaper;
@property (nonatomic, strong) CCNode *          connectingPaper;
@property (nonatomic, strong) CCNode *          helpPaper;


@end
