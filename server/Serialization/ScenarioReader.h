
#import "kobold2d.h"
#import "Definitions.h"

@class Unit;
@class MapLayer;

@interface ScenarioReader : NSObject

- (void) parseScenario:(NSString *)name forMap:(MapLayer *)map_;

@end
