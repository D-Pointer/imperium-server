
#import "cocos2d.h"
#import "Definitions.h"

@interface Smoke : CCSprite

@property (nonatomic, assign) PlayerId creator;

// drift the smoke and update the opacity. Returns YES if the smoke has faded away and NO to keep it
- (BOOL) update:(CGPoint)drift;

@end
