
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "Definitions.h"

// export stuff to Javascript
@protocol PlayerJS <JSExport>

@property (nonatomic, readonly) PlayerId   playerId;
@property (nonatomic, readonly) PlayerType type;
@property (nonatomic, strong)   NSString * name;

@end


@interface Player : NSObject <PlayerJS>

@property (nonatomic, readonly) PlayerId   playerId;
@property (nonatomic, readonly) PlayerType type;
@property (nonatomic, strong)   NSString * name;

- (id) initWithId:(PlayerId)playerId type:(PlayerType)type;

@end
