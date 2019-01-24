
#import "Definitions.h"

@class Unit;
@class MapLayer;
@class Scenario;

@interface MapReader : NSObject

- (void) completeScenario:(Scenario *)scenario;

- (Scenario *) parseScenarioMetaData:(NSString *)name;

@end
