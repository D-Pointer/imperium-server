
#import "cocos2d.h"
#import "Layer.h"

@interface EditArmy : Layer

@property (nonatomic, strong) CCMenuItemImage * backButton;
@property (nonatomic, strong) CCMenuItemImage * infantryButton;
@property (nonatomic, strong) CCMenuItemImage * artilleryButton;
@property (nonatomic, strong) CCMenuItemImage * supportButton;
@property (nonatomic, strong) CCNode *          messagePaper;
@property (nonatomic, strong) CCNode *          buttonsPaper;
@property (nonatomic, strong) CCNode *          forcesPaper;
@property (nonatomic, strong) CCNode *          baseForcesNode;
@property (nonatomic, strong) CCLabelBMFont *   creditsLabel;
@property (nonatomic, strong) CCLabelBMFont *   unitCountLabel;
@property (nonatomic, strong) CCMenu *          forcesMenu;

+ (CCScene *) node;

@end
