
#import "cocos2d.h"
#import "Definitions.h"

@interface GameInfo : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCLabelBMFont *   titleLabel;
@property (nonatomic, strong) CCLabelBMFont *   lengthLabel;
@property (nonatomic, strong) CCLabelBMFont *   descriptionLabel;
@property (nonatomic, strong) CCMenu *          menu;
@property (nonatomic, strong) CCMenuItemImage * detailedButton;

+ (GameInfo *) node;

@end
