
#import "IsHeadquarterAlive.h"
#import "Organization.h"

@implementation IsHeadquarterAlive

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.organization.headquarter && context.unit.organization.headquarter.destroyed == NO ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
