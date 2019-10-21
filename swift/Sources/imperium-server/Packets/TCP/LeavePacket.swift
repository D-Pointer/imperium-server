
import NIO
import Foundation

class LeavePacket : Packet {

    var debugDescription: String {
        return "[Leave]"
    }

    var type: PacketType

    init(buffer: ByteBuffer) {
        self.type = .leaveGamePacket
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

        if game.started {
            // send "game ended"
            Log.info("\(player): left game \(game), ending it")
            sendGameEnded(to: game.players[0], state: state)
            sendGameEnded(to: game.players[1], state: state)

            game.endTime = Date()
        }
        else {
            // not started, broadcast "game removed"
            Log.info("\(player): left game \(game), removing it")

            var buffer = ctx.channel.allocator.buffer(capacity: 8)
            buffer.writeInteger(UInt16(6))
            buffer.writeInteger(PacketType.gameRemovedPacket.rawValue)
            buffer.writeInteger(UInt32(game.id))
            state.send(buffer: buffer, channels: state.players.map{ (key, value) in
                return value.channel
            })
        }

        // log statistics
        state.playersSyncQueue.async {
            Statistics().save(game: game)
            game.players.forEach{ $0.game = nil }
            game.players.removeAll()
        }

        state.games.removeValue(forKey: game.id)
    }

    private func sendGameEnded(to player: Player, state: ServerState) {
        var buffer = player.channel.allocator.buffer(capacity: 2)
        buffer.writeInteger(UInt16(2))
        buffer.writeInteger(PacketType.gameEndedPacket.rawValue)
        state.send(buffer: buffer, channel: player.channel)
    }
}
