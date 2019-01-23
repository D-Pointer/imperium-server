
#import "TcpPacket.h"
#import "HostedGame.h"

@interface JoinPacket : TcpPacket

- (instancetype) initWithGame:(HostedGame *)game;

@end
