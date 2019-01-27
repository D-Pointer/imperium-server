
#import "LoginPacket.h"
#import "NetworkUtils.h"
#import "Definitions.h"

@implementation LoginPacket

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kLoginPacket;

        // name as a byte array
        const char *nameBytes = name.UTF8String;
        unsigned short nameLength = (unsigned short)strlen( nameBytes );

        // password as a byte array
        const char *passwordBytes = sServerPassword.UTF8String;
        unsigned short passwordLength = (unsigned short)strlen( passwordBytes );

        // allocate the final buffer, start at 2 to skip the packet length which comes first
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 2;

        // packet type and length
        //offset = saveInt16ToBuffer( packetLength, buffer, offset );
        offset = saveInt16ToBuffer( self.type, buffer, offset );
        offset = saveInt16ToBuffer( sProtocolVersion, buffer, offset );

        // name
        offset = saveInt16ToBuffer( nameLength, buffer, offset );
        memcpy( buffer + offset, nameBytes, nameLength );
        offset += nameLength;

        // password
        offset = saveInt16ToBuffer( passwordLength, buffer, offset );
        memcpy( buffer + offset, passwordBytes, passwordLength );
        offset += passwordLength;

        // finally write in the total size at the start of the packet
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 0 );

        //NSLog( @"packet length: %d, offset: %d", sTcpPacketHeaderLength + packetLength, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}


@end
