
#import "cocos2d.h"

#import "BonjourClient.h"
#import "GCDAsyncSocket.h"
#import "Layer.h"

@interface Connect : Layer <BonjourClientDelegate, GCDAsyncSocketDelegate>

@property (nonatomic, strong) CCMenu *          menu;
@property (nonatomic, strong) CCNode *          gamesPaper;
@property (nonatomic, strong) CCMenuItemImage * backButton;

@end
