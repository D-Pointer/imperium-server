
#import "MultiplayerTimeCondition.h"
#import "Globals.h"
#import "Scenario.h"

@implementation MultiplayerTimeCondition

- (instancetype) initWithLength:(int)length {
    self = [super init];
    if (self) {
        self.length = length;
    }

    return self;
}


- (ScenarioState) check {
    Globals * globals = [Globals sharedInstance];

    // enough time progressed?
    if ( globals.clock.elapsedTime >= self.length ) {
        // game has ended and it's always player2 that wins
        NSLog( @"game ends, elapsed: %.1f, length: %d", [Globals sharedInstance].clock.elapsedTime, self.length );
        self.text = @"Scenario failed... You have ran out of time.";
        self.winner = kPlayer2;
        globals.onlineGame.endType = kTimeOut;

        return kGameFinished;
    }

    return kGameInProgress;
}

@end
