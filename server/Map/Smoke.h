
#import <Foundation/Foundation.h>
#import "Definitions.h"

@interface Smoke : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) int     opacity;

// drift the smoke and update the opacity. Returns YES if the smoke has faded away and NO to keep it
- (BOOL) update:(CGPoint)drift;

@end
