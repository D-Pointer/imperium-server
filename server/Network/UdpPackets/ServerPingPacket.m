
#import <time.h>

#import "ServerPingPacket.h"

@implementation ServerPingPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kUdpPingPacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // type
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );

        // current time
        clock_t now = clock();
        offset = saveInt32ToBuffer( now, buffer, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }
    
    return self;
}

@end
