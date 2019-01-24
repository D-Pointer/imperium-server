
#import "TimeCondition.h"
#import "Globals.h"
#import "Scenario.h"

@implementation TimeCondition

- (instancetype) initWithLength:(int)length {
    self = [super init];
    if (self) {
        self.length = length;
    }

    return self;
}


- (ScenarioState) check {
    // enough time progressed?
    if ( [Globals sharedInstance].clock.elapsedTime >= self.length ) {
        // game has ended and it's always player2 that wins
        CCLOG( @"game ends, elapsed: %.1f more than length: %d", [Globals sharedInstance].clock.elapsedTime, self.length );
        self.text = @"Scenario failed... You have ran out of time.";
        self.winner = kPlayer2;
        return kGameFinished;
    }

    return kGameInProgress;
}

@end
