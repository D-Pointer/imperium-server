
#import "KeepAlivePacket.h"
#import "NetworkUtils.h"

@implementation KeepAlivePacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kKeepAlivePacket;

        // allocate the final buffer, start at 2 to skip the packet length which comes first
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 2;

        // packet type and length
        offset = saveInt16ToBuffer( self.type, buffer, offset );

        // finally write in the total size at position 0 right after the packet type
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 0 );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}

@end
