
#import "cocos2d.h"
#import "Definitions.h"

@interface EndGamePrompt : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCMenuItemImage * endGameButton;

+ (EndGamePrompt *) node;

@end
