
#import "SmokePacket.h"
#import "Smoke.h"
#import "Globals.h"
#import "MapLayer.h"

@implementation SmokePacket

- (instancetype) initWithSmoke:(CCArray *)smoke {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kSmokePacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // save the offset so that we can later fill in the number of smokes
        unsigned short countOffset = offset;

        // skip the count
        offset += sizeof( unsigned short );

        PlayerId localPlayerId = [Globals sharedInstance].localPlayer.playerId;

        unsigned short count = 0;

        for ( Smoke * tmpSmoke in smoke ) {
            // our smoke? we only send smoke that we have created
            if ( tmpSmoke.creator == localPlayerId ) {
                offset = saveInt16ToBuffer( (unsigned short)(tmpSmoke.position.x * 10), buffer, offset );
                offset = saveInt16ToBuffer( (unsigned short)(tmpSmoke.position.y * 10), buffer, offset );
                offset = saveInt8ToBuffer( (unsigned char)tmpSmoke.opacity, buffer, offset );
                count++;
            }
        }

        CCLOG( @"sending %d smoke data, offset: %d", count, offset );
        
        // finally add in the smoke count at the saved count offset
        saveInt16ToBuffer( count, buffer, countOffset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }
    
    return self;
}


@end
