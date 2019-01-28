
#import "TcpPacket.h"

@interface SetupUnitsPacket : TcpPacket

- (instancetype) initWithUnits:(NSArray *)units;

@end
