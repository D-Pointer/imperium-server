
#import "ReadyToStartPacket.h"
#import "NetworkUtils.h"

@implementation ReadyToStartPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kReadyToStartPacket;

        // total packet length
        unsigned short packetLength = 0;

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 0;

        // packet type and length
        offset = saveInt16ToBuffer( self.type, buffer, offset );
        offset = saveInt16ToBuffer( packetLength, buffer, offset );

        //NSLog( @"packet length: %d, offset: %d", sTcpPacketHeaderLength + packetLength, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}

@end
