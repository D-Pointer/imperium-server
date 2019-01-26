
#import "UdpPacket.h"

@class Unit;

@interface UnitStatsPacket : UdpPacket

- (instancetype) initWithUnits:( NSMutableArray *)units;

@end
