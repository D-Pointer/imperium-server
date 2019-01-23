
#import "cocos2d.h"
#import "Definitions.h"

@interface HelpOverlay : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCLabelBMFont * pauseLabel;
@property (nonatomic, strong) CCLabelBMFont * unitInfoLabel;
@property (nonatomic, strong) CCLabelBMFont * changeModeLabel;
@property (nonatomic, strong) CCLabelBMFont * autoFireLabel;
@property (nonatomic, strong) CCLabelBMFont * centerLabel;
@property (nonatomic, strong) CCLabelBMFont * nextUnitLabel;
@property (nonatomic, strong) CCLabelBMFont * previousUnitLabel;
@property (nonatomic, strong) CCLabelBMFont * hqLabel;
@property (nonatomic, strong) CCLabelBMFont * cancelMissionLabel;
@property (nonatomic, strong) CCSprite *      changeModeLine;
@property (nonatomic, strong) CCSprite *      autoFireLine;
@property (nonatomic, strong) CCSprite *      centerLine;
@property (nonatomic, strong) CCSprite *      nextUnitLine;
@property (nonatomic, strong) CCSprite *      previousUnitLine;
@property (nonatomic, strong) CCSprite *      hqLine;
@property (nonatomic, strong) CCSprite *      cancelMissionLine;

+ (HelpOverlay *) node;

@end
