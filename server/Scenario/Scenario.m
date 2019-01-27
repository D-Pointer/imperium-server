
#import "Scenario.h"
#import "Globals.h"

@implementation Scenario

- (id) init {
    self = [super init];
    if (self) {
        self.startTime = 12 * 3600;

        // assume not playable and not completed
        self.battleSize = kNotIncluded;

        //self.polygons = [ NSMutableArray array];
        self.width    = -1;
        self.height   = -1;

        // by default depends on nothing
        self.dependsOn = -1;

        // no victory conditions by default
        self.victoryConditions = [ NSMutableArray array];

        // empty starting positions
        self.startingPositions = [ NSMutableArray array];
    }

    return self;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"[Scenario %d, %@]", self.scenarioId, self.title];
}


- (void) setScenarioId:(short)scenarioId {
    _scenarioId = scenarioId;
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
