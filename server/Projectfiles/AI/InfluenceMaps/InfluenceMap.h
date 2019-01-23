
#import "MapBase.h"
#import "UnitStrengthMap.h"

@interface InfluenceMap : MapBase {

}

- (id) initWithAI:(UnitStrengthMap *)ai human:(UnitStrengthMap *)human;

- (void) update;


@end
