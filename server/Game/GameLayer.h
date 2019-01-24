
#import "Layer.h"
#import "MapLayer.h"
#import "PanZoomNode.h"
#import "TcpNetworkHandler.h"

@class GameMenuPopup;

@interface GameLayer : Layer <OnlineGamesDelegate, PanZoomNodeDelegate>

@property (nonatomic, readonly) CGRect visibleMapRect;
@property (nonatomic, readonly) CGPoint panOffset;

- (void) reset;

- (void) gameAboutToEnd;

- (void) showGameMenuPopup;

- (void) centerMapOn:(Unit *)unit;

- (CGPoint) convertMapCoordinateToWorld:(CGPoint)pos;

- (void) startOnlineGame;

+ (id) node;


@end
