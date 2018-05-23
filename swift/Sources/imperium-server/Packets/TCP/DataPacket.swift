
import NIO
import Foundation

class DataPacket : Packet {

    var debugDescription: String {
        return "[Data]"
    }

    var type: PacketType

    let data: ByteBuffer

    init?(buffer: ByteBuffer) {
        self.type = .dataPacket

        // save the whole buffer for sending to the other player
        // TODO: this includes headers too?
        self.data = buffer.slice()
    }

    
    func handle (ctx: ChannelHandlerContext, state: ServerState) throws {
        state.mutex.lock()
        defer {
            state.mutex.unlock()
        }

        let id = ObjectIdentifier(ctx.channel)
        guard let player = state.players[id] else {
            Log.error("no player found for id \(id)")
            throw PacketException.playerNotFound
        }

        guard let game = player.game else {
            // send "no game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.write(integer: UInt16(2))
            buffer.write(integer: PacketType.noGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        guard game.started else {
            // TODO: game has not started, can not send data
            return
        }

        // statistics
        game.tcpBytes += UInt64(data.readableBytes)
        game.tcpPackets += 1
        game.lastTcpPacket = Date()

        let opponent = game.players[0] == player ? game.players[1] : game.players[0]

        state.send(buffer: self.data, channel: opponent.channel)
    }
}
