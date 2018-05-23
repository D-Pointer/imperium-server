
import CoreFoundation
import NIO

final class PacketFactory {

    func createPacket(buffer: ByteBuffer) -> Packet? {
        guard let tmpPacketType = buffer.getInteger(at: 2, endianness: .big, as: UInt16.self) else {
            return nil
        }

        guard let packetType = PacketType(rawValue: tmpPacketType) else {
            Log.error("invalid packet type: \(tmpPacketType)")
            return nil
        }

        var packet: Packet?

        switch packetType {
        case .loginPacket: packet = LoginPacket(buffer: buffer)
        case .loginOkPacket: break
        case .invalidProtocolPacket: break
        case .alreadyLoggedInPacket: break
        case .invalidNamePacket: break
        case .nameTakenPacket: break
        case .serverFullPacket: break
        case .announceGamePacket: packet = AnnouncePacket(buffer: buffer)
        case .announceOkPacket: break
        case .alreadyAnnouncedPacket: break
        case .gameAddedPacket: break
        case .gameRemovedPacket: break
        case .leaveGamePacket: packet = LeavePacket(buffer: buffer)
        case .noGamePacket: break
        case .joinGamePacket: packet = JoinPacket(buffer: buffer)
        case .gameJoinedPacket: break
        case .invalidGamePacket: break
        case .alreadyHasGamePacket: break
        case .gameFullPacket: break
        case .gameEndedPacket: break
        case .dataPacket: packet = DataPacket(buffer: buffer)
        case .readyToStartPacket: break
        case .keepAlivePacket: break
        case .playerCountPacket: break
        case .invalidPasswordPacket: break
        }

        return packet
    }
}
