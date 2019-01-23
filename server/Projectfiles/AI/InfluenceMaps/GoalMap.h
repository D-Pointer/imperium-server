
#import "MapBase.h"
#import "UnitStrengthMap.h"

@interface GoalMap : MapBase

- (id) initWithAI:(UnitStrengthMap *)ai human:(UnitStrengthMap *)human;

- (void) update;

@end
