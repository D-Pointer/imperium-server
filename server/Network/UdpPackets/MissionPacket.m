
#import "MissionPacket.h"
#import "Mission.h"
#import "Unit.h"

@implementation MissionPacket

- (instancetype) initWithUnits:( NSMutableArray *)units {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kUdpDataPacket;
        self.subType = kMissionPacket;

        // get a buffer
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
            // unit id, mission
            offset = saveInt16ToBuffer( unit.unitId, buffer, offset );
            offset = saveInt8ToBuffer( unit.mission.type & 0xff, buffer, offset );
        }

        //CCLOG( @"packet length: %d", offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset freeWhenDone:NO];
    }
    
    return self;
}

@end
