
#import "VictoryCondition.h"

@interface HoldAllObjectivesCondition : VictoryCondition

@property (nonatomic, assign) PlayerId playerId;
@property (nonatomic, assign) int      length;
@property (nonatomic, assign) float    startHold1;
@property (nonatomic, assign) float    startHold2;

- (instancetype) initWithPlayerId:(PlayerId)playerId length:(int)length;

@end
