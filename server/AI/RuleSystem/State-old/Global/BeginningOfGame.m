
#import "BeginningOfGame.h"
#import "Clock.h"
#import "Globals.h"

@implementation BeginningOfGame

- (void) update:(UnitContext *)context {
    context.ruleSystem.state[ GlobIsBeginningOfGame ] = @( [Globals sharedInstance].clock.elapsedTime < 300 );
}

@end
