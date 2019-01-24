
#import <Foundation/Foundation.h>

@class UnitContext;

@interface Info : NSObject

@property (nonatomic, assign) float lastUpdated;
@property (nonatomic, assign) float updateInterval;

- (BOOL) updateRequired:(float)time;

- (void) update:(UnitContext *)context;

@end
