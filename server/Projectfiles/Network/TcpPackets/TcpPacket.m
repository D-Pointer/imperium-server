
#import "TcpPacket.h"

#define TCP_PACKET_BUFFER_SIZE 2048

@implementation TcpPacket

- (NSString *) description {
    return [NSString stringWithFormat:@"[%@ TCP %lu bytes]", self.class, (unsigned long)self.data.length];
}


- (NSString *) name {
    return NSStringFromClass( [self class] );
}


- (unsigned char *) getBuffer {
    return malloc( TCP_PACKET_BUFFER_SIZE );
}


+ (NSString *) name:(TcpNetworkPacketType)packetType {
    switch (packetType) {
        case kLoginPacket:
            return @"LoginPacket";
        case kLoginOkPacket:
            return @"LoginOkPacket";
        case kInvalidProtocolPacket:
            return @"InvalidProtocolPacket";
        case kAlreadyLoggedInPacket:
            return @"AlreadyLoggedInPacket";
        case kInvalidNamePacket:
            return @"InvalidNamePacket";
        case kNameTakenPacket:
            return @"NameTakenPacket";
        case kServerFullPacket:
            return @"ServerFullPacket";
        case kAnnounceGamePacket:
            return @"AnnounceGamePacket";
        case kAnnounceOkPacket:
            return @"AnnounceOkPacket";
        case kAlreadyAnnouncedPacket:
            return @"AlreadyAnnouncedPacket";
        case kGameAddedPacket:
            return @"GameAddedPacket";
        case kGameRemovedPacket:
            return @"GameRemovedPacket";
        case kLeaveGamePacket:
            return @"LeaveGamePacket";
        case kNoGamePacket:
            return @"NoGamePacket";
        case kJoinGamePacket:
            return @"JoinGamePacket";
        case kGameJoinedPacket:
            return @"GameJoinedPacket";
        case kInvalidGamePacket:
            return @"InvalidGamePacket";
        case kAlreadyHasGamePacket:
            return @"AlreadyHasGamePacket";
        case kGameFullPacket:
            return @"GameFullPacket";
        case kGameEndedPacket:
            return @"GameEndedPacket";
        case kDataPacket:
            return @"DataPacket";
        case kReadyToStartPacket:
            return @"ReadyToStartPacket";
        case kPlayerCountPacket:
            return @"PlayerCountPacket";
            
        default:
            return [NSString stringWithFormat:@"unknown packet type: %d", packetType];
    }
}

@end
