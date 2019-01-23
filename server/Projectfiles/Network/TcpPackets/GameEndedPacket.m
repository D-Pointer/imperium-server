#import "GameEndedPacket.h"
#import "Globals.h"
#import "Scenario.h"
#import "NetworkUtils.h"

@implementation GameEndedPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kDataPacket;

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 0;

        // packet type
        offset = saveInt16ToBuffer( (unsigned short) self.type, buffer, offset );

        // skip the length, we fill it in when the package is done
        offset += sizeof( unsigned short );

        // sub type
        buffer[offset++] = kGameResultPacket & 0xff;

        // multiplayer end type
        buffer[offset++] = [Globals sharedInstance].onlineGame.endType & 0xff;

        // end game data
        ScoreCounter *scores = [Globals sharedInstance].scores;
        offset = saveInt16ToBuffer( (unsigned short) [scores getTotalMen:kPlayer1], buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) [scores getTotalMen:kPlayer2], buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) [scores getLostMen:kPlayer1], buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) [scores getLostMen:kPlayer2], buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) [scores getObjectivesScore:kPlayer1], buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short) [scores getObjectivesScore:kPlayer2], buffer, offset );

        // finally write in the total size at position 2 right after the packet type
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 2 );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}


@end
