
#import "VictoryCondition.h"

@interface DestroyUnitCondition : VictoryCondition

@property (nonatomic, assign) int unitId;

- (instancetype) initWithUnitId:(int)unitId;

@end
