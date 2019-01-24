
#import "VictoryCondition.h"

@interface TimeCondition : VictoryCondition

@property (nonatomic, assign) int length;

- (instancetype) initWithLength:(int)length;

@end
