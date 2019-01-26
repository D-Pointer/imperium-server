
#import "UdpPacket.h"

@class Unit;

@interface SmokePacket : UdpPacket

- (instancetype) initWithSmoke:( NSMutableArray *)smoke;

@end
