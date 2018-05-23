import NIO

final class UdpPacketHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>

    let factory: UdpPacketFactory

    let serverState: ServerState

    init(serverState: ServerState, factory: UdpPacketFactory) {
        self.serverState = serverState
        self.factory = factory
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let envelope = self.unwrapInboundIn(data)
        let remoteAddress = envelope.remoteAddress
        let buffer = envelope.data

        Log.debug("incoming UDP: \(remoteAddress), size: \(buffer.readableBytes)")

        guard let packet = factory.createPacket(buffer: buffer) else {
            Log.error("invalid UDP packet")
            return
        }

        Log.debug("received \(packet)")
        do {
            try packet.handle(ctx: ctx, state: self.serverState, sender: remoteAddress)
        }
        catch PacketException.playerNotFound {
            Log.error("player not found while handling: \(packet.debugDescription)")
        }
        catch PacketException.playerHasNoGame {
            Log.error("player has no game while handling: \(packet.debugDescription)")
        }
        catch PacketException.playerHasNoAddress {
            Log.error("opponent has no address while handling: \(packet.debugDescription)")
        }
        catch PacketException.invalidGame(let gameId) {
            Log.error("invalid game: \(gameId) while handling: \(packet.debugDescription)")
        }
        catch {
            Log.error("other error: \(error)")
        }
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        Log.debug("UDP channel active")
    }
}

