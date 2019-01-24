
#import "Globals.h"

@interface Action : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign) BOOL       isTrue;
@property (nonatomic, readonly) BOOL     isFalse;
@property (nonatomic, strong) NSNumber * value;
@property (nonatomic, strong) Unit *     foundUnit;

/**
 * Updates the condition value.
 **/
- (void) update;

@end
