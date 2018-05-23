
public enum PacketType : UInt16 {
    case loginPacket = 0 // in
    case loginOkPacket // out
    case invalidProtocolPacket
    case alreadyLoggedInPacket
    case invalidNamePacket // error out
    case nameTakenPacket // error out
    case serverFullPacket // error out
    case announceGamePacket // in
    case announceOkPacket // out
    case alreadyAnnouncedPacket // error out
    case gameAddedPacket // out
    case gameRemovedPacket // 
    case leaveGamePacket // in
    case noGamePacket // error out
    case joinGamePacket // in
    case gameJoinedPacket // out
    case invalidGamePacket // error out
    case alreadyHasGamePacket // error out
    case gameFullPacket // error out
    case gameEndedPacket // out
    case dataPacket // 20 out
    case readyToStartPacket // out

    case keepAlivePacket
    case playerCountPacket

    case invalidPasswordPacket
}

