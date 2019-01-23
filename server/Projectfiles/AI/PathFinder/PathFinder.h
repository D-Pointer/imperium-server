
#import "Unit.h"

/**
 * Class that can find a path between two given positions on the map.
 *
 * @see http://www.policyalmanac.org/games/aStarTutorial.htm
 **/
@interface PathFinder : NSObject

- (id) initWithData:(Byte *)data;

- (Path *) findPathFrom:(CGPoint)source to:(CGPoint)destination forUnit:(Unit *)unit;

/**
 * Returns the terrain type at the position (x,y) in the low resolution terrain map.
 **/
- (TerrainType) getTerrainAtX:(int)x y:(int)y;

@end
