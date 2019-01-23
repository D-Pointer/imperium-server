
#import "TcpPacket.h"
#import "Scenario.h"

@interface AnnouncePacket : TcpPacket

- (instancetype) initWithScenario:(Scenario *)scenario;

@end
