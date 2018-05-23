
import NIO
import Foundation

final class Player : Equatable, CustomStringConvertible, Encodable {

    static var nextId: UInt32 = 0

    let id: UInt32
    let channel: Channel
    let connectedTime: Date

    var name: String = ""

    // an optional game the player is in
    var game: Game?

    // the UDP address to the player
    var address: SocketAddress?

    var description: String {
        if let game = game {
            return "[Player id:\(id) name:\(name) game:\(game.id)]"
        }
        else {
            return "[Player id:\(id) name:\(name) game:no]"
        }
    }

    init(channel: Channel) {
        self.id = Player.nextId
        Player.nextId += 1

        self.channel = channel
        self.connectedTime = Date()
    }

    //
    // MARK: - Equatable
    //
    static func ==(lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }

    //
    // MARK: - Encodable
    //
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case connectedTime = "connected"
    }
}

