
#import <GameplayKit/GameplayKit.h>

#import "UnitContext.h"

@interface State : NSObject

@property (nonatomic, strong) NSString * name;

- (void) evaluate:(UnitContext *)context;

@end

