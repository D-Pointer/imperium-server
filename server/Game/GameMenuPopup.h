
#import "cocos2d.h"
#import "Definitions.h"

@interface GameMenuPopup : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCMenuItemImage *  helpButton;
@property (nonatomic, strong) CCMenuItemImage *  infoButton;
@property (nonatomic, strong) CCMenuItemImage *  quitButton;
@property (nonatomic, strong) CCMenuItemImage *  startButton;
@property (nonatomic, strong) CCMenuItemImage *  optionsButton;
@property (nonatomic, strong) CCLabelBMFont *    titleLabel;
@property (nonatomic, strong) CCLabelBMFont *    subtitleLabel;
@property (nonatomic, strong) CCMenu *           menu;

+ (GameMenuPopup *) node;

@end
