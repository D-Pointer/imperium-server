
#import "Definitions.h"
#import "BehaviorTreeContext.h"

@interface Node : NSObject

@property (nonatomic, assign) unsigned int nodeId;
@property (nonatomic, strong) NSString *   comment;
@property (nonatomic, assign) int          value;
@property (nonatomic, assign) int          level;

/**
 * Parses and sets the optional "value" string. The default just sets it as an integer into self.value.
 **/
- (void) parseValue:(NSString *)value;

- (BehaviorTreeResult) process:(BehaviorTreeContext *)context;

- (BehaviorTreeResult) failed:(BehaviorTreeContext *)context;
- (BehaviorTreeResult) running:(BehaviorTreeContext *)context;
- (BehaviorTreeResult) succeeded:(BehaviorTreeContext *)context;

- (BehaviorTreeResult) returnResult:(BehaviorTreeResult)result context:(BehaviorTreeContext *)context;

- (NSString *)indentedDescription;

@end
