
import NIO
import Foundation

final class PacketHandler: ChannelInboundHandler {
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
        Log.error("error: \(error)")

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }

    
    public func channelActive(ctx: ChannelHandlerContext) {
        let remoteAddress = ctx.remoteAddress!
        let channel = ctx.channel

        Log.debug("channel active: \(remoteAddress)")

        serverState.mutex.lock()
        defer {
            serverState.mutex.unlock()
        }

        self.serverState.players[ObjectIdentifier(channel)] = Player(channel: channel)
        Log.debug("players now: \(self.serverState.players.count)")
    }


    public func channelInactive(ctx: ChannelHandlerContext) {
        let channel = ctx.channel
        let id = ObjectIdentifier(channel)

        serverState.mutex.lock()
        defer {
            serverState.mutex.unlock()
        }

        guard let player = self.serverState.players[id] else {
            Log.error("no player found for id \(id)")
            return
        }

        Log.debug("player inactive: \(player)")

        self.serverState.players.removeValue(forKey: ObjectIdentifier(channel))
        self.serverState.playerLookup.removeValue(forKey: player.id)
        Log.debug("players now: \(self.serverState.players.count)")

        // does the player have a game?
        if let game = player.game {
            self.serverState.games.removeValue(forKey: game.id)

            // has it started?
            if game.started {
                // send "game ended" to the opponent
                var buffer = ctx.channel.allocator.buffer(capacity: 2)
                buffer.write(integer: UInt16(2))
                buffer.write(integer: PacketType.gameEndedPacket.rawValue)
                self.serverState.send(buffer: buffer, channel: game.players[1].channel)

                game.endTime = Date()
            }
            else {
                // broadcast "game removed"
                var buffer = ctx.channel.allocator.buffer(capacity: 8)
                buffer.write(integer: UInt16(6))
                buffer.write(integer: PacketType.gameRemovedPacket.rawValue)
                buffer.write(integer: UInt32(game.id))
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
}

