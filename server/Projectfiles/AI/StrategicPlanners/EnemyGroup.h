
#import "cocos2d.h"
#import "Unit.h"

@interface EnemyGroup : NSObject

@property (nonatomic, strong) CCArray * enemies;

- (id) initWithEnemies:(CCArray *)enemies;
- (id) initWithEnemy:(Unit *)enemy;

- (BOOL) is:(Unit *)unit closerThan:(float)distance;

@end
