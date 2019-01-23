
#import "MeleePacket.h"
#import "Unit.h"

@implementation MeleePacket

- (instancetype) initWithAttacker:(Unit *)attacker target:(Unit *)target message:(AttackMessageType)message
                       casualties:(int)casualties targetMoraleChange:(float)targetMoraleChange {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kMeleePacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // all melee data
        offset = saveInt16ToBuffer( (unsigned short)attacker.unitId, buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short)target.unitId, buffer, offset );
        offset = saveInt8ToBuffer( (unsigned char)(message & 0xff), buffer, offset );
        offset = saveInt8ToBuffer( (unsigned char)(casualties & 0xff), buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short)(targetMoraleChange * 10), buffer, offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }
    
    return self;
}


@end
