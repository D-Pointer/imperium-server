
#import "cocos2d.h"
#import "Layer.h"

@interface MultiplayerSetupGame : Layer

@property (nonatomic, strong) CCMenuItemImage * smallButton;
@property (nonatomic, strong) CCMenuItemImage * mediumButton;
@property (nonatomic, strong) CCMenuItemImage * largeButton;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCNode *          messagePaper;
@property (nonatomic, strong) CCNode *          buttonsPaper;

+ (CCScene *) node;

@end
