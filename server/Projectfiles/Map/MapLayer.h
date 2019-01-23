
#import <JavaScriptCore/JavaScriptCore.h>

#import "PanZoomNode.h"
#import "Definitions.h"
#import "LineOfSightVisualizer.h"
#import "FiringRangeVisualizer.h"
#import "CommandRangeVisualizer.h"
#import "SelectionMarker.h"
#import "Smoke.h"

@class Unit;
@class Objective;
@class PolygonNode;
@class House;

// export stuff to Javascript
@protocol MapLayerJS <JSExport>
@property (nonatomic)         int                      mapWidth;
@property (nonatomic)         int                      mapHeight;
@property (nonatomic, strong) CCArray *                polygons;

- (void) addOffMapArtilleryExplosion:(CGPoint)position;

@end


@interface MapLayer : CCNode <MapLayerJS>

@property (nonatomic)         int                      mapWidth;
@property (nonatomic)         int                      mapHeight;
@property (nonatomic, strong) CCArray *                polygons;
@property (nonatomic, strong) CCArray *                smoke1;
@property (nonatomic, strong) CCArray *                smoke2;
@property (nonatomic, strong) PolygonNode *            baseGrass;
@property (nonatomic, strong) LineOfSightVisualizer *  losVisualizer;
@property (nonatomic, strong) FiringRangeVisualizer *  rangeVisualizer;
@property (nonatomic, strong) CommandRangeVisualizer * commandRangeVisualizer;
@property (nonatomic, strong) SelectionMarker *        selectionMarker;


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

// adds a number of bodies randomly around the given unit
- (void) addBodies:(int)bodies around:(Unit *)unit;

// adds the given house and shadow
- (void) addHouse:(House *)house withShadow:(CCSprite *)shadow;

- (void) addSmoke:(CGPoint)position forPlayer:(PlayerId)player ;

- (void) addOffMapArtilleryExplosion:(CGPoint)position;

@end
