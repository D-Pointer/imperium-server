
#import "cocos2d.h"
#import "Conditions.h"

@interface Rule : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign) int        priority;

- (instancetype) initWithPriority:(int)priority;

- (BOOL) checkRuleForUnit:(Unit *)unit withConditions:(Conditions *)conditions;

- (CCSprite *) createDebuggingNode;

@end
