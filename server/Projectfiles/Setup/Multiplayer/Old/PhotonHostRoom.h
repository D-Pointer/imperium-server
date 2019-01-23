
#import "Layer.h"
#import "NetworkLogicDelegate.h"

@interface PhotonHostRoom : Layer <NetworkLogicDelegate, QuestionDelegate>

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          paper;

@end
