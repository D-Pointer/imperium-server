
#import "FirePacket.h"
#import "Unit.h"
#import "AttackResult.h"

@implementation FirePacket

- (instancetype) initWithAttacker:(Unit *)attacker casualties:(CCArray *)casualties hitPosition:(CGPoint)hitPosition {
    self = [super init];
    if (self) {
        self.type = kUdpDataPacket;
        self.subType = kFirePacket;

        // get a buffer
        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // attacker id
        offset = saveInt16ToBuffer( (unsigned short)attacker.unitId, buffer, offset );

        // hit position
        offset = saveInt16ToBuffer( (unsigned short)(hitPosition.x * 10), buffer, offset );
        offset = saveInt16ToBuffer( (unsigned short)(hitPosition.y * 10), buffer, offset );

        // number of casualties
        offset = saveInt8ToBuffer( (unsigned char)(casualties.count & 0xff), buffer, offset );

        // any casualties at all?
        if ( casualties != nil ) {
            for ( AttackResult * result in casualties ) {
                // target id
                offset = saveInt16ToBuffer( (unsigned short)result.target.unitId, buffer, offset );
                offset = saveInt8ToBuffer( (unsigned char)(result.casualties & 0xff), buffer, offset );
                offset = saveInt8ToBuffer( (unsigned char)(result.messageType & 0xff), buffer, offset );
                offset = saveInt16ToBuffer( (unsigned short)(result.targetMoraleChange * 10), buffer, offset );
            }
        }

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }
    
    return self;
}


@end
