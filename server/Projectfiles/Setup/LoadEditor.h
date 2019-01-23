
#import "cocos2d.h"
#import "Layer.h"

@interface LoadEditor : Layer <UITextFieldDelegate>

@property (nonatomic, strong) CCNode *          paper;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCLabelBMFont *   status;

@end
