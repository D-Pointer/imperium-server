
import CoreFoundation
import NIO

final class UdpPacketFactory {

    func createPacket(buffer: ByteBuffer) -> UdpPacket? {
        guard let tmpPacketType = buffer.getInteger(at: 0, endianness: .big, as: UInt8.self) else {
            return nil
        }

        guard let packetType = UdpPacketType(rawValue: tmpPacketType) else {
            Log.error("invalid UDP packet type: \(tmpPacketType)")
            return nil
        }

        var packet: UdpPacket? 

        switch packetType {
        case .udpPingPacket: packet = PingPacket(buffer: buffer)
        case .udpPongPacket: break
        case .udpDataPacket: packet = UdpDataPacket(buffer: buffer)
        case .startActionPacket: break
        }

        return packet
    }
}

