
#import "cocos2d.h"

@class Unit;

@interface MissionVisualizer : CCNode

- (id) initWithUnit:(Unit *)unit;

- (void) refresh;

@end
