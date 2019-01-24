
#import "cocos2d.h"
#import "Definitions.h"

@interface QuitConfirm : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCLabelBMFont *   message;
@property (nonatomic, strong) CCMenuItemImage * quitButton;
@property (nonatomic, strong) CCMenuItemImage * cancelButton;

+ (QuitConfirm *) node;

@end
