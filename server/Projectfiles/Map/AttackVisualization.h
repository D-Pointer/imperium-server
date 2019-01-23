
#import "cocos2d.h"
#import "Definitions.h"

@class Unit;


@interface AttackVisualization : NSObject

- (id) initWithAttacker:(Unit *)attacker casualties:(CCArray *)casualties hitPosition:(CGPoint)hitPosition;

- (id) initWithAttacker:(Unit *)attacker smokePosition:(CGPoint)smokePosition;

- (void) execute;


@end
