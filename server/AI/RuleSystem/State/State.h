
#import <GameplayKit/GameplayKit.h>

#import "UnitContext.h"

@interface State : NSObject

- (void) update:(UnitContext *)context forRuleSystem:(GKRuleSystem *)ruleSystem;

@end

