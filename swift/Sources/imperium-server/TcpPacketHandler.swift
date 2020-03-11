
import NIO
import Foundation

final class TcpPacketHandler: ChannelInboundHandler {
    public typealias InboundIn = Packet
    public typealias OutboundOut = ByteBuffer

    let serverState: ServerState

    init(serverState: ServerState) {
        self.serverState = serverState
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let packet = self.unwrapInboundIn(data)

        do {
            try packet.handle(ctx: ctx, state: self.serverState)
        }
        catch PacketException.playerNotFound {
            Log.error("player not found while handling: \(packet.debugDescription)")
        }
        catch PacketException.playerHasNoGame {
            Log.error("player has no game while handling: \(packet.debugDescription)")
        }
        catch PacketException.invalidGame(let gameId) {
            Log.error("invalid game: \(gameId) while handling: \(packet.debugDescription)")
        }
        catch {
            Log.error("other error: \(error)")
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        if let player = self.getPlayer(ctx: ctx) {
            Log.error("\(player) error: \(error)")
        }
        else {
            Log.error("unknown player, error: \(error)")
        }

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }


    public func channelActive(ctx: ChannelHandlerContext) {
        let remoteAddress = ctx.remoteAddress!
        let channel = ctx.channel

        serverState.mutex.lock()
        defer {
            serverState.mutex.unlock()
        }

        let player = Player(channel: channel)
        self.serverState.players[ObjectIdentifier(channel)] = player
        Log.debug("\(player) connected, players now: \(self.serverState.players.count)")
    }


    public func channelInactive(ctx: ChannelHandlerContext) {
        let id = ObjectIdentifier(ctx.channel)

        serverState.mutex.lock()
        defer {
            serverState.mutex.unlock()
        }

        guard let player = self.getPlayer(ctx: ctx) else {
            Log.error("no player found for id \(id)")
            return
        }

        self.serverState.players.removeValue(forKey: ObjectIdentifier(ctx.channel))
        self.serverState.playerLookup.removeValue(forKey: player.id)
        Log.debug("\(player) disconnected, players now: \(self.serverState.players.count)")

        // does the player have a game?
        if let game = player.game {
            self.serverState.games.removeValue(forKey: game.id)

            // has it started?
            if game.started {
                // send "game ended" to the opponent
                var buffer = ctx.channel.allocator.buffer(capacity: 2)
                buffer.writeInteger(UInt16(2))
                buffer.writeInteger(PacketType.gameEndedPacket.rawValue)
                self.serverState.send(buffer: buffer, channel: game.players[1].channel)

                game.endTime = Date()
            }
            else {
                // broadcast "game removed"
                var buffer = ctx.channel.allocator.buffer(capacity: 8)
                buffer.writeInteger(UInt16(6))
                buffer.writeInteger(PacketType.gameRemovedPacket.rawValue)
                buffer.writeInteger(UInt32(game.id))
                self.serverState.send(buffer: buffer, channels: self.serverState.players.map{ (key, value) in
                    return value.channel
                })
            }

            // log statistics
            self.serverState.playersSyncQueue.async {
                Statistics().save(game: game)
            }
        }
    }

    private func getPlayer(ctx: ChannelHandlerContext) -> Player? {
        let id = ObjectIdentifier(ctx.channel)
        return self.serverState.players[id]
    }
}
