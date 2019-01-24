#import "SetMissionPacket.h"
#import "Unit.h"

@implementation SetMissionPacket

- (instancetype) initWitUnit:(Unit *)unit mission:(MissionType)mission {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kSetMissionPacket;

        // get a buffer
        unsigned char *buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // all melee data
        offset = saveInt16ToBuffer( (unsigned short) unit.unitId, buffer, offset );
        offset = saveInt8ToBuffer( (unsigned char) (mission & 0xff), buffer, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }

    return self;
}


@end
