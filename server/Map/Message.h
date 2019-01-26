

#import "Definitions.h"

@class Unit;


@interface Message : NSObject

@property (nonatomic, weak)   Unit *        unit;
@property (nonatomic, assign) MessageType   message;

- (id) initWithMessage:(MessageType)message forUnit:(Unit *)unit;

- (void) execute;

@end
