
#import "cocos2d.h"
#import "Layer.h"

@interface About : Layer

@property (nonatomic, strong) CCLabelBMFont *   version;
@property (nonatomic, strong) CCLabelBMFont *   versionName;
@property (nonatomic, strong) CCNode *          codePaper;
@property (nonatomic, strong) CCNode *          photosPaper;
@property (nonatomic, strong) CCNode *          audioPaper;
@property (nonatomic, strong) CCNode *          graphicsPaper;
@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * reviewButton;

@end
