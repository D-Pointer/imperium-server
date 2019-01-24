
#import "DefendScenario.h"
#import "Scenario.h"
#import "Globals.h"

@implementation DefendScenario

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ GlobIsDefendScenario ] = @( [Globals sharedInstance].scenario.aiHint == kPlayer1Attacks );
}

@end
