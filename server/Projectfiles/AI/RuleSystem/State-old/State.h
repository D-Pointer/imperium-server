
#import <GameplayKit/GameplayKit.h>

#import "UnitContext.h"
#import "StateKeys.h"

@interface State : NSObject

- (void) update:(UnitContext *)context;

@end

