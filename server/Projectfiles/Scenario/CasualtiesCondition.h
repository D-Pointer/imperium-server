
#import "VictoryCondition.h"

@interface CasualtiesCondition : VictoryCondition

@property (nonatomic, assign) float percentage;

- (instancetype) initWithPercentage:(int)percentage;

@end
