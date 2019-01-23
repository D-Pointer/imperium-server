
#import <Foundation/Foundation.h>

@interface Debugging : NSObject

/**
 * Prints the entire node tree below the given node.
 **/
+ (void) printTree:(CCNode *)node;

+ (void) showLineFrom:(CGPoint)start to:(CGPoint)end;

@end
