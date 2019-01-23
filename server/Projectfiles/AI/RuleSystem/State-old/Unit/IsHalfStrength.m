
#import "IsHalfStrength.h"
#import "Scenario.h"

@implementation IsHalfStrength

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    float percentage = (float)context.unit.men / (float)context.unit.originalMen;
    if ( percentage >= 30 && percentage < 70 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
