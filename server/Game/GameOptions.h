
#import "cocos2d.h"
#import "Definitions.h"

@interface GameOptions : CCNode <CCTouchOneByOneDelegate>

@property (nonatomic, strong) CCMenu *           menu;
@property (nonatomic, strong) CCMenuItemImage *  sfxButton;
@property (nonatomic, strong) CCMenuItemImage *  ambienceButton;
@property (nonatomic, strong) CCMenuItemImage *  commandButton;
@property (nonatomic, strong) CCMenuItemImage *  missionsButton;
@property (nonatomic, strong) CCMenuItemImage *  firingRangeButton;

+ (GameOptions *) node;

@end
