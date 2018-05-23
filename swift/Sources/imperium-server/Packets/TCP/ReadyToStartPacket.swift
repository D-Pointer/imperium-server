
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
            buffer.write(integer: UInt16(2))
            buffer.write(integer: PacketType.noGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        // does the player have an opponent in the game?
        guard game.players.count == 2 else {
            // no, send "invalid game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.write(integer: UInt16(2))
            buffer.write(integer: PacketType.invalidGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        // game starts now
        game.startTime = Date()

        Log.info("\(player): ready to start game \(game)")

        // TODO: not done!
        
        // send "announce ok"
        var buffer = ctx.channel.allocator.buffer(capacity: 8)
        buffer.write(integer: UInt16(6))
        buffer.write(integer: PacketType.announceOkPacket.rawValue)
        buffer.write(integer: game.id)
        state.send(buffer: buffer, channel: ctx.channel)

        // send "game added"
        let nameBytes: [UInt8] = Array(game.owner.name.utf8)
        let length = 2 + 4 + 2 + 2 + nameBytes.count
        var gameBuffer = ctx.channel.allocator.buffer(capacity: 2 + length)
        gameBuffer.write(integer: UInt16(length))
        gameBuffer.write(integer: PacketType.gameAddedPacket.rawValue)
        gameBuffer.write(integer: UInt32(game.id))
        gameBuffer.write(integer: game.scenarioId)
        gameBuffer.write(integer: UInt16(nameBytes.count))
        gameBuffer.write(bytes: nameBytes)

        state.send(buffer: gameBuffer, channels: state.players.map{ (key, value) in
            return value.channel
        })
    }
}
