
#import "HasHq.h"

@implementation HasHq

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.headquarter && [context.unit.headquarter canBeGivenMissions] ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
