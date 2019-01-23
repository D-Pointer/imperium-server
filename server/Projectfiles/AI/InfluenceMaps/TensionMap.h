
#import "MapBase.h"
#import "UnitStrengthMap.h"

@interface TensionMap : MapBase

- (id) initWithAI:(UnitStrengthMap *)ai human:(UnitStrengthMap *)human;

- (void) update;

@end
