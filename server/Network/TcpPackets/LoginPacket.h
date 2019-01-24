
#import "TcpPacket.h"

@interface LoginPacket : TcpPacket

- (instancetype)initWithName:(NSString *)name;

@end
