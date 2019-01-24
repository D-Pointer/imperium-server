#import "UdpPacket.h"

@interface PlayerPongPacket : UdpPacket

- (instancetype) initWithTime:(clock_t)ms;

@end
