
#import <Crashlytics/Answers.h>

#import "MultiplayerCasualtiesCondition.h"
#import "Globals.h"
#import "ScoreCounter.h"
#import "Scenario.h"

@implementation MultiplayerCasualtiesCondition

- (instancetype) initWithPercentage:(int)percentage {
    self = [super init];
    if (self) {
        self.percentage = percentage;
    }

    return self;
}


- (ScenarioState) check {
    Globals * globals = [Globals sharedInstance];
    ScoreCounter * scores = globals.scores;

    // a player has lost if 75% of the men are lost
    if ( [scores getLostMen:kPlayer1] > [scores getTotalMen:kPlayer1] * (self.percentage / 100.0f) ) {
        CCLOG( @"player 1 has lost > 75%% of the men, game ends" );
        self.text = @"Scenario failed... Your army has taken too heavy casualties";
        self.winner = kPlayer2;
        globals.onlineGame.endType = kPlayer1Destroyed;

        [Answers logCustomEventWithName:@"Multiplayer scenario over"
                       customAttributes:@{ @"title" : globals.scenario.title,
                                           @"reason" : @"Player destroyed",
                                           @"winner" : @"player 2"
                                           }];
        return kGameFinished;
    }

    if ( [scores getLostMen:kPlayer2] > [scores getTotalMen:kPlayer2] * (self.percentage / 100.0f) ) {
        CCLOG( @"player 2 has lost > 75%% of the men, game ends" );
        self.text = @"Scenario completed! The Perseutian force has been destroyed";
        self.winner = kPlayer1;
        globals.onlineGame.endType = kPlayer2Destroyed;

        [Answers logCustomEventWithName:@"Multiplayer scenario over"
                       customAttributes:@{ @"title" : globals.scenario.title,
                                           @"reason" : @"Player destroyed",
                                           @"winner" : @"player 1"
                                           }];
        return kGameFinished;
    }

    // still in progress
    return kGameInProgress;
}

@end
