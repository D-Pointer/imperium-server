#import "WindPacket.h"
#import "Globals.h"
#import "Scenario.h"
#import "NetworkUtils.h"

@implementation WindPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kDataPacket;

        CCLOG( @"sending wind data" );

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 0;

        // packet type
        offset = saveInt16ToBuffer( (unsigned short) self.type, buffer, offset );

        // skip the length, we fill it in when the package is done
        offset += sizeof( unsigned short );

        // sub type
        buffer[offset++] = kWindPacket & 0xff;

        // wind direction and strength
        offset = saveInt16ToBuffer( (unsigned short) ([Globals sharedInstance].scenario.windDirection * 10), buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) ([Globals sharedInstance].scenario.windStrength * 10), buffer, offset );

        // finally write in the total size at position 2 right after the packet type
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 2 );

        //CCLOG( @"packet length: %d", offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}


@end
