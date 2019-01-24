
#import "UdpPacket.h"

@class Unit;

@interface FirePacket : UdpPacket

- (instancetype) initWithAttacker:(Unit *)attacker casualties:(CCArray *)casualties hitPosition:(CGPoint)hitPosition;

@end
