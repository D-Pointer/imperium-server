
#import "cocos2d.h"
#import "Definitions.h"

@interface StartPrompt : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCLabelBMFont *   message;
@property (nonatomic, strong) CCMenuItemImage * startButton;

+ (StartPrompt *) node;

@end
