
#import "MapBase.h"
#import "InfluenceMap.h"

@interface FrontlineMap : MapBase

- (id) initWithInfluenceMap:(InfluenceMap *)influenceMap;

- (void) update;

@end
