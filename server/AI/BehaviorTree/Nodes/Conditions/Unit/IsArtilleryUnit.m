
#import "IsArtilleryUnit.h"

@implementation IsArtilleryUnit

- (BehaviorTreeResult) update:(BehaviorTreeContext *)context {
    if ( context.unit.type == kArtillery ) {
        return kSucceeded;
    }

    return kFailed;
}

@end
