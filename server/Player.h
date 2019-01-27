
#import <Foundation/Foundation.h>
#import "Definitions.h"


@interface Player : NSObject

@property (nonatomic, readonly) PlayerId   playerId;
@property (nonatomic, strong)   NSString * name;

- (id) initWithId:(PlayerId)playerId;

@end
