
#import "VictoryCondition.h"

@interface MultiplayerTimeCondition : VictoryCondition

@property (nonatomic, assign) int length;

- (instancetype) initWithLength:(int)length;

@end
