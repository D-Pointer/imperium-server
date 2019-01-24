
#import <Foundation/Foundation.h>
#import "Definitions.h"


@interface Player : NSObject

@property (nonatomic, readonly) PlayerId   playerId;
@property (nonatomic, readonly) PlayerType type;
@property (nonatomic, strong)   NSString * name;

- (id) initWithId:(PlayerId)playerId type:(PlayerType)type;

@end
