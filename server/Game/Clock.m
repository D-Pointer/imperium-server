

#import "Clock.h"
#import "Definitions.h"
#import "Globals.h"
#import "Scenario.h"

@interface Clock ()

// timestamp used for internal timing
@property (nonatomic, strong) NSDate * baseTime;

@end


@implementation Clock

- (instancetype) init {
    self = [super init];
    if (self) {
        self.elapsedTime = 0;
        self.lastElapsedTime = 0;
    }
    return self;
}


- (float) currentTime {
    // time is in seconds
    return [Globals sharedInstance].scenario.startTime + self.elapsedTime;
}


- (void) start {
    self.baseTime = [NSDate date];
    self.startRealTime = self.baseTime;
    self.lastElapsedTime = 0;
}


- (float) advanceTime {
    NSAssert( self.baseTime, @"invalid base time" );

    // get the current time
    NSDate * now = [NSDate date];

    NSTimeInterval delta = [now timeIntervalSinceDate:self.baseTime];
    //NSTimeInterval totalRealtime = [now timeIntervalSinceDate:self.startRealTime];

    // store the time elapsed since this method was last called
    self.lastElapsedTime = delta * sParameters[kParamTimeMultiplierF].floatValue;

    // add to the total
    self.elapsedTime += self.lastElapsedTime;

//    NSLog( @"real elapsed time:       %.2f", delta );
//    NSLog( @"total real elapsed time: %.2f", totalRealtime );
//    NSLog( @"sim elapsed time:        %.2f", self.lastElapsedTime );
//    NSLog( @"total sim elapsed time:  %.2f", self.elapsedTime );

    self.baseTime = now;

    return self.elapsedTime;
}


- (NSString *) formattedTime {
    int time = (int)self.currentTime;

    int hours   = time / 3600;
    int minutes = (time - hours * 3600) / 60;
    int seconds = time % 60;

    // the string to actually show
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}


@end
