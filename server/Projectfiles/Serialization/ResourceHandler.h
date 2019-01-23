
#import "Definitions.h"

@interface ResourceHandler : NSObject

+ (BOOL) hasResource:(NSString *)name;

+ (NSString *) loadResource:(NSString *)name;

+ (BOOL) saveData:(NSString *)data toResource:(NSString *)name;

+ (BOOL) deleteResource:(NSString *)name;

@end
