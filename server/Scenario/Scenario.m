
#import "Scenario.h"
#import "Globals.h"

#define DEFAULTS_KEY @"campaign%d.scenario%d.completed"

@interface Scenario () {
    // completed flag for all 4 campaigns
    BOOL completed[4];
}

@end


@implementation Scenario

- (id) init {
    self = [super init];
    if (self) {
        self.startTime = 12 * 3600;

        // assume not playable and not completed
        self.scenarioType = kCampaign;
        self.battleSize = kNotIncluded;

        //self.polygons = [CCArray array];
        self.width    = -1;
        self.height   = -1;

        // by default depends on nothing
        self.dependsOn = -1;

        // no victory conditions by default
        self.victoryConditions = [CCArray array];

        // empty starting positions
        self.startingPositions = [CCArray array];
    }

    return self;
}


- (NSString *)description {
    switch ( self.scenarioType ) {
        case kCampaign:
            return [NSString stringWithFormat:@"[Scenario %d, %@, campaign: %d,%d,%d,%d]", self.scenarioId, self.title, completed[0], completed[1], completed[2], completed[3]];

        case kTutorial:
            return [NSString stringWithFormat:@"[Scenario %d, %@, tutorial: %d,%d,%d,%d]", self.scenarioId, self.title, completed[0], completed[1], completed[2], completed[3]];

        case kMultiplayer:
            return [NSString stringWithFormat:@"[Scenario %d, %@, multiplayer]", self.scenarioId, self.title];
    }
}


- (void) setScenarioId:(short)scenarioId {
    _scenarioId = scenarioId;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    for ( unsigned int campaignIndex = 0; campaignIndex < 4; ++campaignIndex ) {
        completed[campaignIndex] = [defaults boolForKey:[NSString stringWithFormat:DEFAULTS_KEY, campaignIndex, self.scenarioId]];
    }
}


- (BOOL) isPlayableForCampaign:(int)campaignId {
    if ( self.dependsOn == -1 ) {
        return YES;
    }

    // are we completed?
    if ( completed[ campaignId ] ) {
        // already completed, we can always be replayed
        return YES;
    }

    for ( Scenario * scenario in [Globals sharedInstance].scenarios ) {
        //CCLOG( @"%d %d %d", scenario.scenarioId, self.dependsOn, scenario.isCompleted );
        if ( scenario.scenarioId == self.dependsOn && [scenario isCompletedForCampaign:campaignId] ) {
            // the scenario we depend on is already completed, we can progress
            return YES;
        }
    }

    // not playable
    return NO;
}


- (BOOL) isCompletedForCampaign:(int)campaignId {
    return completed[ campaignId ];
}


- (void) setCompletedForCampaign:(int)campaignId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // save to disk too
    completed[campaignId] = YES;
    [defaults setBool:YES forKey:[NSString stringWithFormat:DEFAULTS_KEY, campaignId, self.scenarioId]];
    [defaults synchronize];
}


- (void) clearCompletedForCampaign:(int)campaignId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // save to disk too
    completed[campaignId] = NO;
    [defaults setBool:NO forKey:[NSString stringWithFormat:DEFAULTS_KEY, campaignId, self.scenarioId]];
    [defaults synchronize];
}


- (ScenarioState) state {
    // update the scores
    [[Globals sharedInstance].scores calculateFinalScores];
    
    // check all the victory conditions
    for ( VictoryCondition * victoryCondition in self.victoryConditions ) {
        if ( [victoryCondition check] != kGameInProgress ) {
            self.endCondition = victoryCondition;
            return kGameFinished;
        }
    }

    // no condition says we're done
    return kGameInProgress;
}
                                                              

@end
