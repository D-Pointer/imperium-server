
#import "AttackScenario.h"
#import "Globals.h"
#import "Scenario.h"

@implementation AttackScenario

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ GlobIsAttackScenario ] = @( [Globals sharedInstance].scenario.aiHint == kPlayer2Attacks );
}

@end
