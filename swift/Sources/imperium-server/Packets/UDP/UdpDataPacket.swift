
import NIO
import Foundation

class UdpDataPacket : UdpPacket {

    var debugDescription: String {
        return "[UdpData \(data.readableBytes)]"
    }

    var type: UdpPacketType

    let playerId: UInt32
    var data: ByteBuffer

    init?(buffer: ByteBuffer) {
        self.type = .udpDataPacket

        guard let playerId = buffer.getInteger(at: 1, endianness: .big, as: UInt32.self) else {
            Log.error("failed to decode data")
            return nil
        }

        guard let data = buffer.getSlice(at: 5, length: buffer.readableBytes - 5) else {
            Log.error("failed to read data buffer")
            return nil
        }

        self.playerId = playerId
        self.data = data
    }


    func handle (ctx: ChannelHandlerContext, state: ServerState, sender: SocketAddress) throws {
        state.mutex.lock()
        defer {
            state.mutex.unlock()
        }

        // do we need to save the UDP address to the player?
        guard let player = state.playerLookup[playerId] else {
            Log.error("no player found for id \(playerId)")
            throw PacketException.playerNotFound
        }

        guard let game = player.game else {
            Log.error("no game found for player id \(playerId)")
            throw PacketException.playerHasNoGame
        }

        let opponent = game.players[0] == player ? game.players[1] : game.players[0]

        guard let opponentAddress = opponent.address else {
            Log.error("player has no UDP address, can not send data: \(opponent)")
            throw PacketException.playerHasNoAddress
        }

        // statistics
        game.udpBytes += UInt64(data.readableBytes)
        game.udpPackets += 1
        game.lastUdpPacket = Date()

        Log.debug("sending data to \(opponent)")

        // send "data"
        var buffer = ctx.channel.allocator.buffer(capacity: 1 + data.readableBytes)
        buffer.writeInteger(UdpPacketType.udpDataPacket.rawValue)
        buffer.writeData(&self.data)

        let envelope = AddressedEnvelope(remoteAddress: opponentAddress, data: buffer)
        ctx.writeAndFlush(NIOAny(envelope), promise: nil)
    }
}
