
#import "Definitions.h"

@interface VictoryCondition : NSObject

@property (nonatomic, strong) NSString *         text;
@property (nonatomic, assign) PlayerId           winner;

- (void) setup;

- (ScenarioState) check;

@end
