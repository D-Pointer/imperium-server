
#include "Definitions.h"

@interface TcpPacket : NSObject

@property (nonatomic, assign) TcpNetworkPacketType type;
@property (nonatomic, assign) NSString *name;
@property (nonatomic, strong) NSData *data;

+ (NSString *) name:(TcpNetworkPacketType)packetType;

- (unsigned char *) getBuffer;

@end
