
import NIO
import Foundation

class JoinPacket : Packet {

    var debugDescription: String {
        return "[Join game:\(gameId)]"
    }


    var type: PacketType

    let gameId: UInt32

    init?(buffer: ByteBuffer) {
        self.type = .joinGamePacket

        guard let gameId = buffer.getInteger(at: 4, endianness: .big, as: UInt32.self) else {
            Log.error("failed to decode game id")
            return nil
        }

        self.gameId = gameId
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

        // player already has a game?
        if player.game != nil {
            // send "already has game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.alreadyHasGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        // find the game
        guard let game = state.games[gameId] else {
            // send "invalid game"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.invalidGamePacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        guard !game.started else {
            // send "game full"
            var buffer = ctx.channel.allocator.buffer(capacity: 4)
            buffer.writeInteger(UInt16(2))
            buffer.writeInteger(PacketType.gameFullPacket.rawValue)
            state.send(buffer: buffer, channel: ctx.channel)
            return
        }

        Log.info("\(player): joined game \(game)")

        game.players.append(player)
        player.game = game
        game.joinTime = Date()

        // send "game joined" to both players
        sendGameJoined(to: game.players[0], opponent: game.players[1], state: state)
        sendGameJoined(to: game.players[1], opponent: game.players[0], state: state)

        // broadcast "game removed"
        var buffer = ctx.channel.allocator.buffer(capacity: 8)
        buffer.writeInteger(UInt16(6))
        buffer.writeInteger(PacketType.gameRemovedPacket.rawValue)
        buffer.writeInteger(UInt32(game.id))
        state.send(buffer: buffer, channels: state.players.map{ (key, value) in
            return value.channel
        })
    }

    private func sendGameJoined(to player: Player, opponent: Player, state: ServerState) {
        let nameBytes: [UInt8] = Array(opponent.name.utf8)
        let length = 2 + 4 + 2 + nameBytes.count
        var buffer = player.channel.allocator.buffer(capacity: 2 + length)

        buffer.writeInteger(UInt16(length))
        buffer.writeInteger(PacketType.gameJoinedPacket.rawValue)
        buffer.writeInteger(player.id)
        buffer.writeInteger(UInt16(nameBytes.count))
        buffer.writeBytes(nameBytes)

        state.send(buffer: buffer, channel: player.channel)
    }
}
