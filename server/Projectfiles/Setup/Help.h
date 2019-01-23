
#import "cocos2d.h"
#import "Layer.h"

@interface Help : Layer

@property (nonatomic, strong) CCNode *          helpPaper;
@property (nonatomic, strong) CCNode *          topicsPaper;
@property (nonatomic, strong) CCMenu *          topicsMenu;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, assign) BOOL              inGameHelp;

+ (CCScene *) inGameNode;

@end
