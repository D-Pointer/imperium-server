

#import "Definitions.h"

@class Unit;
@class Objective;
@class PolygonNode;
@class House;

@interface Map : NSObject

@property (nonatomic)         int                      mapWidth;
@property (nonatomic)         int                      mapHeight;
@property (nonatomic, strong)  NSMutableArray *                polygons;


- (void) reset;

// checks if the given position is inside the map
- (BOOL) isInsideMap:(CGPoint)pos;

// returns the terrain type at the given position
- (TerrainType) getTerrainAt:(CGPoint)pos;

/**
 * Returns the terrain type under the given unit. Samples some positions around the unit and uses the
 * terrain type that got most samples. If the unit is in column mode and even one of the samples are on a road
 * then the unit is assumed to be on a road.
 **/
- (TerrainType) getTerrainForUnit:(Unit *)unit;

- (Unit *) getUnitAt:(CGPoint)pos;
- (Objective *) getObjectiveAt:(CGPoint)pos;

- (BOOL) canSeeFrom:(CGPoint)start to:(CGPoint)end visualize:(BOOL)visualize withMaxRange:(float)maxSightRange;

@end
