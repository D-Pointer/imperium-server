
#import "UdpPacket.h"

@class Unit;

@interface UnitStatsPacket : UdpPacket

- (instancetype) initWithUnits:(CCArray *)units;

@end
