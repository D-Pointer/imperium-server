
#import "UdpPacket.h"

@class Unit;

@interface FirePacket : UdpPacket

- (instancetype) initWithAttacker:(Unit *)attacker casualties:( NSMutableArray *)casualties hitPosition:(CGPoint)hitPosition;

@end
