
#import "PlayerPingPacket.h"

@implementation PlayerPingPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kPlayerPingPacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // current time
        clock_t now = clock();
        offset = saveInt32ToBuffer( now, buffer, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }

    return self;
}

@end
