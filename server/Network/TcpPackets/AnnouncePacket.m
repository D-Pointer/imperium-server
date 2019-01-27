
#import "AnnouncePacket.h"
#import "NetworkUtils.h"

@implementation AnnouncePacket

- (instancetype) initWithScenario:(Scenario *)scenario {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kAnnounceGamePacket;

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 2;

        // packet type and length
        offset = saveInt16ToBuffer( self.type, buffer, offset );
        offset = saveInt16ToBuffer( scenario.scenarioId, buffer, offset );

        // finally write in the total size at the start of the packet
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 0 );

        //NSLog( @"packet length: %d, offset: %d", sTcpPacketHeaderLength + packetLength, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}


@end
