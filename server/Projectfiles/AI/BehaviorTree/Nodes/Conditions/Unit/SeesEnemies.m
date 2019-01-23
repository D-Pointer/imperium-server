
#import "SeesEnemies.h"
#import "Globals.h"
#import "LineOfSight.h"

@implementation SeesEnemies

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.losData.seenCount > 0 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
