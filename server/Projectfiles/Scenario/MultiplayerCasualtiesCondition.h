
#import "VictoryCondition.h"

@interface MultiplayerCasualtiesCondition : VictoryCondition

@property (nonatomic, assign) float percentage;

- (instancetype) initWithPercentage:(int)percentage;

@end
