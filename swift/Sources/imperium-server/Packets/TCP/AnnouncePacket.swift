
import NIO
import Foundation

class AnnouncePacket : Packet {

    var debugDescription: String {
        return "[Announce scenario:\(scenarioId)]"
    }


    var type: PacketType

    let scenarioId: UInt16

    init?(buffer: ByteBuffer) {
        self.type = .loginPacket

        guard let scenarioId = buffer.getInteger(at: 4, endianness: .big, as: UInt16.self) else {
                Log.error("failed to decode data")
                return nil
        }

        self.scenarioId = scenarioId
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

        if player.game != nil {
            // send "already announced"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.alreadyAnnouncedPacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        let game = Game(scenarioId: scenarioId, owner: player)
        game.announceTime = Date()
        state.games[game.id] = game
        player.game = game
        Log.info("\(player): announced new game \(game), games now \(state.games.count)")

        // send "announce ok"
        var buffer = ctx.channel.allocator.buffer(capacity: 8)
        buffer.writeInteger(UInt16(6))
        buffer.writeInteger(PacketType.announceOkPacket.rawValue)
        buffer.writeInteger(game.id)
        state.send(buffer: buffer, channel: ctx.channel)

        // send "game added"
        let nameBytes: [UInt8] = Array(game.owner.name.utf8)
        let length = 2 + 4 + 2 + 2 + nameBytes.count
        var gameBuffer = ctx.channel.allocator.buffer(capacity: 2 + length)
        gameBuffer.writeInteger(UInt16(length))
        gameBuffer.writeInteger(PacketType.gameAddedPacket.rawValue)
        gameBuffer.writeInteger(UInt32(game.id))
        gameBuffer.writeInteger(game.scenarioId)
        gameBuffer.writeInteger(UInt16(nameBytes.count))
        gameBuffer.writeBytes(nameBytes)

        state.send(buffer: gameBuffer, channels: state.players.map{ (key, value) in
            return value.channel
        })
    }
}
