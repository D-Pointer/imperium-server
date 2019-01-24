
#import "cocos2d.h"

@interface Panel : CCNode

@property (nonatomic, strong) CCLabelBMFont *    nameLabel;
@property (nonatomic, strong) CCLabelBMFont *    hqLabelInCommand;
@property (nonatomic, strong) CCLabelBMFont *    hqLabelNotInCommand;
@property (nonatomic, strong) CCLabelBMFont *    hqLabelDestroyed;
@property (nonatomic, strong) CCLabelBMFont *    menLabel;
@property (nonatomic, strong) CCLabelBMFont *    missionLabel;
@property (nonatomic, strong) CCLabelBMFont *    terrainLabel;
@property (nonatomic, strong) CCLabelBMFont *    modeLabel;
@property (nonatomic, strong) CCLabelBMFont *    weaponLabel;
@property (nonatomic, strong) CCLabelBMFont *    experienceLabel;
@property (nonatomic, strong) CCLabelBMFont *    ammoLabel;
@property (nonatomic, strong) CCLabelBMFont *    moraleLabel;
@property (nonatomic, strong) CCLabelBMFont *    fatigueLabel;
@property (nonatomic, strong) CCLabelBMFont *    pingLabel;
@property (nonatomic, strong) CCMenuItemSprite * nextButton;
@property (nonatomic, strong) CCMenuItemSprite * previousButton;
@property (nonatomic, strong) CCMenuItemSprite * hqButton;
@property (nonatomic, strong) CCMenuItemSprite * findButton;
@property (nonatomic, strong) CCMenuItemSprite * cancelButton;
@property (nonatomic, strong) CCMenuItemSprite * changeModeButton;
@property (nonatomic, strong) CCMenuItemSprite * toggleAutoFireButton;
@property (nonatomic, strong) CCMenuItemSprite * helpButton;

// names of all terrain, indexed by their type enum
@property (nonatomic, strong) CCArray *          terrainNames;


+ (Panel *) node;

- (void) showServerPing:(double)ms;

@end
