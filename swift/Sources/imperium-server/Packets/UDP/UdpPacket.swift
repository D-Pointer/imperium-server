
import NIO

protocol UdpPacket : CustomDebugStringConvertible {
    var type: UdpPacketType { get }

    func handle (ctx: ChannelHandlerContext, state: ServerState, sender: SocketAddress) throws
}



