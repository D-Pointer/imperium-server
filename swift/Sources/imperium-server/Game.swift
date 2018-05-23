
import Foundation

final class Game : Encodable, CustomStringConvertible {

    static var nextId: UInt32 = 0
    let id: UInt32

    let scenarioId: UInt16
    var players: [Player] = []

    var owner: Player {
        return players.first!
    }

    var started: Bool {
        return players.count == 2
    }

    var description: String {
        return "[Game id:\(id) scenario:\(scenarioId) owner:\(players.first!.id)]"
    }

    // times
    var announceTime: Date?
    var joinTime: Date?
    var startTime: Date?
    var endTime: Date?

    // statistics
    var tcpPackets: UInt64 = 0
    var tcpBytes: UInt64 = 0
    var lastTcpPacket: Date?
    var udpPackets: UInt64 = 0
    var udpBytes: UInt64 = 0
    var lastUdpPacket: Date?

    init(scenarioId: UInt16, owner: Player) {
        self.id = Game.nextId
        Game.nextId += 1

        self.scenarioId = scenarioId
        self.players.append(owner)
    }

    //
    // MARK: - Encodable protocol
    //
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioId = "scenario"
        case players = "players"
        case tcpPackets
        case tcpBytes
        case lastTcpPacket
        case udpPackets
        case udpBytes
        case lastUdpPacket
    }
}

