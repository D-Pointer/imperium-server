
import NIO
import Foundation

class ReadyToStartPacket : Packet {

    var debugDescription: String {
        return "[ReadyToStart]"
    }

    var type: PacketType

    init?(buffer: ByteBuffer) {
        self.type = .readyToStartPacket
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

        // does the player have a game?
        guard let game = player.game else {
            // no, send "no game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.noGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        // does the player have an opponent in the game?
        guard game.players.count == 2 else {
            // no, send "invalid game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.invalidGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        Log.info("\(player): ready to start game \(game)")

        // the player is now ready to start
        game.readyToStart += 1

        // is the other player also ready?
        if game.readyToStart >= 2 {
            // game starts now
            Log.info("\(game): is starting")
            game.startTime = Date()

            // send a few "start" to both player
            for _ in 0 ..< 5 {
                try game.players.forEach{ player in
                    guard let address = player.address else {
                        Log.error("\(game): can not send start UDP packets, player \(player) has no address")
                        throw PacketException.playerHasNoAddress
                    }

                    var buffer = ctx.channel.allocator.buffer(capacity: 2)
                    buffer.writeInteger(UdpPacketType.startActionPacket.rawValue)

                    let envelope = AddressedEnvelope(remoteAddress: address, data: buffer)
                    ctx.writeAndFlush(NIOAny(envelope), promise: nil)
                }
            }
        }
    }
}
