
import NIO

enum PacketException : Error {
    case playerNotFound
    case playerHasNoGame
    case playerHasNoAddress
    case invalidGame(gameId: UInt32)
}

protocol Packet : CustomDebugStringConvertible {
    var type: PacketType { get }

    func handle (ctx: ChannelHandlerContext, state: ServerState) throws
}


