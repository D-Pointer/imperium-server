
#import "cocos2d.h"
#import "Layer.h"

@interface ResumeGame : Layer

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * resumeButton;
@property (nonatomic, strong) CCMenuItemImage * startNewGameButton;
@property (nonatomic, strong) CCNode *          messagePaper;
@property (nonatomic, strong) CCNode *          buttonsPaper;

@end
