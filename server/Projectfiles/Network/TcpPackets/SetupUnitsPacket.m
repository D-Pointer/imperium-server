#import "SetupUnitsPacket.h"
#import "Globals.h"
#import "Scenario.h"
#import "NetworkUtils.h"

@implementation SetupUnitsPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        // save the type too
        self.type = kDataPacket;

        CCArray *localUnits = [Globals sharedInstance].localUnits;

        CCLOG( @"sending data for %lu units", (unsigned long)localUnits.count );

        // allocate the final buffer
        unsigned char *buffer = [self getBuffer];
        unsigned short offset = 0;

        // packet type
        offset = saveInt16ToBuffer( (unsigned short) self.type, buffer, offset );

        // skip the length, we fill it in when the package is done
        offset += sizeof( unsigned short );

        // sub type
        buffer[offset++] = kSetupUnitsPacket & 0xff;

        // unit count
        buffer[offset++] = (unsigned char) (localUnits.count & 0xff);

        // add in all units
        for (Unit *unit in localUnits) {
            // 4 x unsigned short
            offset = saveInt16ToBuffer( (unsigned short) unit.unitId, buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short) (unit.position.x * 10), buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short) (unit.position.y * 10), buffer, offset );
            offset = saveInt16ToBuffer( (unsigned short) (unit.rotation * 10), buffer, offset );

            // 10 * unsigned char
            buffer[offset++] = (unsigned char) unit.type;
            buffer[offset++] = (unsigned char) unit.men;
            buffer[offset++] = (unsigned char) unit.mode;
            buffer[offset++] = (unsigned char) unit.mission.type;
            buffer[offset++] = (unsigned char) unit.morale;
            buffer[offset++] = (unsigned char) unit.fatigue;
            buffer[offset++] = (unsigned char) unit.experience;
            buffer[offset++] = (unsigned char) unit.weapon.ammo;
            buffer[offset++] = (unsigned char) unit.weapon.type;

            // unit name
            const char *nameBytes = unit.name.UTF8String;
            unsigned char nameLength = (unsigned char) (strlen( nameBytes ) & 0xff);

            buffer[offset++] = nameLength;
            memcpy( buffer + offset, nameBytes, nameLength );
            offset += nameLength;
        }

        // finally write in the total size at position 2 right after the packet type
        saveInt16ToBuffer( offset - sTcpPacketHeaderLength, buffer, 2 );

        //CCLOG( @"packet length: %d", offset );

        // finally wrap the buffer in a NSData
        self.data = [NSData dataWithBytesNoCopy:buffer length:offset];
    }

    return self;
}


@end
