
#import "PlayerPongPacket.h"

@implementation PlayerPongPacket

- (instancetype) initWithTime:(clock_t)ms {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kPlayerPongPacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // add the given time
        offset = saveInt32ToBuffer( ms, buffer, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }

    return self;
}

@end
