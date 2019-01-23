#import "UdpPacket.h"

// start from 1 so that we can use 0 as a "no packet yet"
static unsigned int nextUdpPacketId = 1;

@interface UdpPacket ()

@property (nonatomic, readwrite) unsigned int packetId;

@end

// a set of shared buffers
#define BUFFER_SIZE 2048
#define BUFFER_COUNT 100
static unsigned char *buffers[BUFFER_COUNT];
static BOOL buffersAllocated = NO;
static unsigned int nextBufferIndex = 0;

@implementation UdpPacket

- (instancetype) init {
    self = [super init];
    if (self) {
        self.packetId = nextUdpPacketId++;
    }

    return self;
}


- (NSString *) description {
    if (self.type == kUdpDataPacket) {
        return [NSString stringWithFormat:@"[%@ UDP id: %d, type %@, %lu bytes]", self.class, self.packetId, [UdpPacket subName:self.subType], (unsigned long)self.data.length];
    }
    else {
        return [NSString stringWithFormat:@"[%@ UDP id: %d, %lu bytes]", self.class, self.packetId, (unsigned long)self.data.length];
    }
}


- (NSString *) name {
    return NSStringFromClass( [self class] );
}


+ (NSString *) name:(UdpNetworkPacketType)packetType {
    switch (packetType) {
        case kUdpPingPacket:
            return @"UdpPingPacket";
        case kUdpPongPacket:
            return @"UdpPongPacket";
        case kUdpDataPacket:
            return @"UdpDataPacket";
        case kStartActionPacket:
            return @"StartActionPacket";

        default:
            return [NSString stringWithFormat:@"unknown packet type: %d", packetType];
    }
}


+ (NSString *) subName:(UdpNetworkPacketSubType)packetSubType {
    switch (packetSubType) {
        case kMissionPacket:
            return @"MissionPacket";
        case kUnitStatsPacket:
            return @"UnitStatsPacket";
        case kFirePacket:
            return @"FirePacket";
        case kMeleePacket:
            return @"MeleePacket";
        case kSetMissionPacket:
            return @"SetMissionPacket";
        case kPlayerPingPacket:
            return @"PlayerPingPacket";
        case kPlayerPongPacket:
            return @"PlayerPongPacket";
        case kSmokePacket:
            return @"SmokePacket";
        default:
            return [NSString stringWithFormat:@"unknown packet sub type: %d", packetSubType];
    }
}


+ (unsigned char *) getBuffer {
    // set up the buffers if needed
    if (!buffersAllocated) {
        for (unsigned int index = 0; index < BUFFER_COUNT; ++index) {
            buffers[index] = malloc( BUFFER_SIZE );
        }

        buffersAllocated = YES;
    }

    unsigned char *buffer = buffers[nextBufferIndex];

    // keep the index as [0..BUFFER_COUNT[
    nextBufferIndex = (nextBufferIndex + 1) % BUFFER_COUNT;

    return buffer;
}

@end
