
#import <Foundation/Foundation.h>
#import "Definitions.h"

@interface Army : NSObject

@property (nonatomic, strong) NSMutableArray * unitDefinitions;

+ (void) loadArmies;
+ (void) saveArmies;

- (void) createUnitsForPlayer:(PlayerId)player;

@end