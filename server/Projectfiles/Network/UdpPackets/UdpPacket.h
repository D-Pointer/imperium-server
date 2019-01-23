
#import "Definitions.h"
#import "NetworkUtils.h"

@interface UdpPacket : NSObject

@property (nonatomic, assign) UdpNetworkPacketType type;
@property (nonatomic, assign) UdpNetworkPacketSubType subType;
@property (nonatomic, readonly) unsigned int    packetId;
@property (nonatomic, assign) NSString *name;
@property (nonatomic, strong) NSData *data;

+ (NSString *) name:(UdpNetworkPacketType)packetType;
+ (NSString *) subName:(UdpNetworkPacketSubType)packetSubType;

// private
+ (unsigned char *) getBuffer;

@end
