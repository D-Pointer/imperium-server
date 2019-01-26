#import "UnitStatsPacket.h"
#import "Unit.h"

@implementation UnitStatsPacket

- (instancetype) initWithUnits:( NSMutableArray *)units {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kUdpDataPacket;
        self.subType = kUnitStatsPacket;

        unsigned char * buffer = [UdpPacket getBuffer];
        unsigned short offset = 0;

        // packet type and subtype
        offset = saveInt8ToBuffer( self.type & 0xff, buffer, offset );
        offset = saveInt8ToBuffer( self.subType & 0xff, buffer, offset );

        // packet id
        offset = saveInt32ToBuffer( self.packetId, buffer, offset );

        // unit count
        offset = saveInt8ToBuffer( units.count & 0xff, buffer, offset );

        for ( Unit * unit in units ) {
             // all the data we will send
            offset = saveInt16ToBuffer( (unsigned short)unit.unitId, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.men, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.mode, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.mission.type, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.morale, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.fatigue, buffer, offset );
            offset = saveInt8ToBuffer( (unsigned char)unit.weapon.ammo, buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short)(unit.position.x * 10), buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short)(unit.position.y * 10), buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short)(unit.rotation * 10), buffer, offset );

        }

        //CCLOG( @"packet length: %d", offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }

    return self;
}

@end
