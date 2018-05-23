
import NIO

class PingPacket : UdpPacket {

    var debugDescription: String {
        return "[Ping \(timestamp)]"
    }

    var type: UdpPacketType

    let playerId: UInt32
    let timestamp: UInt64

    init?(buffer: ByteBuffer) {
        self.type = .udpPingPacket

        guard let playerId = buffer.getInteger(at: 1, endianness: .big, as: UInt32.self) else {
            Log.error("failed to decode data")
            return nil
        }

        guard let timestamp = buffer.getInteger(at: 5, endianness: .big, as: UInt64.self) else {
            Log.error("failed to decode data")
            return nil
        }

        self.playerId = playerId
        self.timestamp = timestamp
    }


    func handle (ctx: ChannelHandlerContext, state: ServerState, sender: SocketAddress) throws {
        state.mutex.lock()
        defer {
            state.mutex.unlock()
        }

        // do we need to save the UDP address to the player?
        if let player = state.playerLookup[playerId] {
            Log.debug("sending a pong to \(player)")
        }
        else {
            let player = state.players.values.first{ $0.id == self.playerId }
            guard player != nil else {
                Log.error("no player found for id \(playerId)")
                throw PacketException.playerNotFound
            }

            // player found, save the address
            player?.address = sender
            state.playerLookup[playerId] = player
            Log.debug("registered UDP address and sending a pong to \(player!)")
        }

        // send "pong"
        var buffer = ctx.channel.allocator.buffer(capacity: 5)
        buffer.write(integer: UdpPacketType.udpPongPacket.rawValue)
        buffer.write(integer: timestamp)

        let envelope = AddressedEnvelope(remoteAddress: sender, data: buffer)
        ctx.writeAndFlush(NIOAny(envelope), promise: nil)
    }
}

