
#import "JoinPacket.h"
#import "NetworkUtils.h"

@implementation JoinPacket

- (instancetype) initWithGame:(HostedGame *)game {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kJoinGamePacket;

        // total packet length
        unsigned short packetLength = sizeof( game.gameId );

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 0;

        // packet type and length
        offset = saveInt16ToBuffer( self.type, buffer, offset );
        offset = saveInt16ToBuffer( packetLength, buffer, offset );
        offset = saveInt32ToBuffer( game.gameId, buffer, offset );

        CCLOG( @"packet length: %d, offset: %d", sTcpPacketHeaderLength + packetLength, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}

@end
