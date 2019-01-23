
#import "cocos2d.h"
#import "MapBase.h"

@interface InfluenceMapNode : CCSprite

@property (nonatomic, strong) MapBase * influenceMap;

- (id) initWithMap: (MapBase *)influenceMap;

- (void) update;

//+ (InfluenceMapNode *) showMap:(MapBase *)map;

@end
