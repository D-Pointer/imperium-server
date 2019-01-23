
#import <Foundation/Foundation.h>

@class Unit;

@interface Selection : NSObject

@property (readwrite, nonatomic, weak) Unit * selectedUnit;

- (void) reset;

@end
