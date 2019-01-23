
#import "Layer.h"
#import "NetworkLogicDelegate.h"


@interface PhotonConnectRoom : Layer <NetworkLogicDelegate, QuestionDelegate>

@property (nonatomic, strong) CCMenu *          menu;
@property (nonatomic, strong) CCNode *          gamesPaper;
@property (nonatomic, strong) CCMenuItemImage * backButton;

@end
