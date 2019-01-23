
#import "PolygonNode.h"

@interface ScatteredTrees : PolygonNode

- (id) initWithPolygon:(CCArray *)vertices smoothing:(BOOL)smoothing;

- (void) createTreesFrom:(NSArray *)parts;

@end
