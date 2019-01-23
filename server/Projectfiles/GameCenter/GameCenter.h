
#import <Foundation/Foundation.h>
#import "GameCenter.h"

@protocol GameCenterDelegate <NSObject>

@required

- (void) playerAuthenticated:(NSString *)name;

@end


@interface GameCenter : NSObject

@property (nonatomic, weak)     id<GameCenterDelegate> delegate;
@property (nonatomic, readonly) BOOL                   isAuthenticated;

- (id) initWithDelegate:(id <GameCenterDelegate>)delegate;

- (void) authenticateLocalPlayer;

@end

