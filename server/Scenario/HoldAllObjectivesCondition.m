
#import "HoldAllObjectivesCondition.h"
#import "Globals.h"
#import "Scenario.h"

@implementation HoldAllObjectivesCondition

- (instancetype) initWithPlayerId:(PlayerId)playerId length:(int)length {
    self = [super init];
    if (self) {
        self.playerId = playerId;
        self.length = length;
        self.startHold1 = -1;
        self.startHold2 = -1;
    }

    return self;
}


- (ScenarioState) check {
    NSLog( @"%.1f %d", [Globals sharedInstance].clock.elapsedTime, self.length );

    int held1 = 0;
    int held2 = 0;
    int total = 0;

    // check all objectives
    for ( Objective * objective in [Globals sharedInstance].objectives ) {
        if ( objective.state == kOwnerPlayer1 ) {
            held1++;
        }
        else if ( objective.state == kOwnerPlayer2 ) {
            held2++;
        }

        total++;
    }

    NSLog( @"total: %d, player 1 held: %d, player 2 held: %d", total, held1, held2 );
    
    float currentTime = [Globals sharedInstance].clock.currentTime;

    // player1 holds all objectives?
    if ( held1 == total ) {
        // player 1 holds all objectives, is this the first update?
        if ( self.startHold1 < 0 ) {
            // yes, so the holding time starts now
            NSLog( @"player 1 hold time starts" );
            self.startHold1 = currentTime;
        }
        else {
            NSLog( @"player 1 hold time: %.1f", currentTime - self.startHold1 );

            // the player has held it for a while already, long enough?
            if ( currentTime - self.startHold1 > self.length ) {
                // player 1 has held the objective long enough
                self.winner = kPlayer1;
                self.text = @"Scenario completed! Ourland has held the objectives long enough!";

                // we're done
                return kGameFinished;
            }
        }
    }
    else {
        self.startHold1 = -1;
    }

    // player 2∫ holds all objectives?
    if ( held2 == total ) {
        // player 2 holds all objectives, is this the first update?
        if ( self.startHold2 < 0 ) {
            // yes, so the holding time starts now
            NSLog( @"player 2 hold time starts" );
            self.startHold2 = currentTime;
        }
        else {
            NSLog( @"player 2 hold time: %.1f", currentTime - self.startHold2 );

            // the player has held it for a while already, long enough?
            if ( currentTime - self.startHold2 > self.length ) {
                // player 2 has held the objective long enough
                self.winner = kPlayer2;
                self.text = @"Scenario failed... The Perseuts has held the objectives for too long.";

                // we're done
                return kGameFinished;
            }
        }
    }
    else {
        self.startHold2 = -1;
    }

    // game has not yet ended
    return kGameInProgress;
}

@end
