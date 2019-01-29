
#import "Definitions.h"

@interface GameSerializer : NSObject

+ (BOOL) saveGame:(NSString *)name;
+ (BOOL) loadGame:(NSString *)name;

//+ (BOOL) hasSavedGame:(NSString *)name;
//+ (void) deleteSavedGame:(NSString *)name;

@end
