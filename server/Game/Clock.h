
#include <Foundation/Foundation.h>


@interface Clock : NSObject


// current time in simulation seconds, based on the scenario start time
@property (nonatomic, assign) float            currentTime;

// total elapsed time in simulation seconds
@property (nonatomic, assign) float            elapsedTime;

// last step elapsed time in simulation seconds
@property (nonatomic, assign) float            lastElapsedTime;

// start time
@property (nonatomic, strong) NSDate *         startRealTime;

- (void) start;

// advance the time with the elapsed wall clock time
- (float) advanceTime;

- (NSString *) formattedTime;

- (void) update;

+ (Clock *) node;

@end
