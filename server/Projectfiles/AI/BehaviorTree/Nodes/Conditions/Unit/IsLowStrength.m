
#import "IsLowStrength.h"
#import "Scenario.h"

@implementation IsLowStrength

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    float percentage = (float)context.unit.men / (float)context.unit.originalMen;
    if ( percentage < 30 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
