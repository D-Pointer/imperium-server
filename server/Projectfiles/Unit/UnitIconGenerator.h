
#import "Unit.h"

@interface UnitIconGenerator : NSObject

/**
 * Returns a singleton instance of the generator.
 **/
+ (UnitIconGenerator *) sharedInstance;

- (CCSpriteFrame *) spriteFrameFor:(Unit *)unit;

@end
