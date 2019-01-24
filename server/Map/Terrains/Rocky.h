
#import "PolygonNode.h"

@interface Rocky : PolygonNode

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing;

- (void) createRocksFrom:(NSArray *)parts;

@end
