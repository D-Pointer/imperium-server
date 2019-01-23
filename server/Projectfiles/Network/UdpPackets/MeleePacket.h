#import "UdpPacket.h"

@class Unit;

@interface MeleePacket : UdpPacket

- (instancetype) initWithAttacker:(Unit *)attacker
                           target:(Unit *)target
                          message:(AttackMessageType)message
                       casualties:(int)casualties
               targetMoraleChange:(float)targetMoraleChange;

@end
