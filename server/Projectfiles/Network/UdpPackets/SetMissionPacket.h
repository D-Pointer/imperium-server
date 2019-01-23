#import "UdpPacket.h"
#import "Definitions.h"

@class Unit;

@interface SetMissionPacket : UdpPacket

- (instancetype) initWitUnit:(Unit *)unit mission:(MissionType)mission;
                           ;

@end
