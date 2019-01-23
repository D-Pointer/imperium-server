
#import "IsFullStrength.h"
#import "Scenario.h"

@implementation IsFullStrength

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    float percentage = (float)context.unit.men / (float)context.unit.originalMen;
    if ( percentage >= 70 ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
