
import NIO

class LoginPacket : Packet {

    var debugDescription: String {
        return "[Login version:\(version) user:\(name):\(password)]"
    }


    var type: PacketType

    let version: UInt16
    let name: String
    let password: String

    init?(buffer: ByteBuffer) {
        self.type = .loginPacket

        guard
            let protocolVersion = buffer.getInteger(at: 4, endianness: .big, as: UInt16.self),
            let nameLength = buffer.getInteger(at: 6, endianness: .big, as: UInt16.self) else {
                Log.error("failed to decode data")
                return nil
        }

        guard let name = buffer.getString(at: 8, length: Int(nameLength)) else {
            Log.error("failed to decode name")
            return nil
        }

        guard let passwordLength = buffer.getInteger(at: 8 + Int(nameLength), endianness: .big, as: UInt16.self) else {
            Log.error("failed to decode password length")
            return nil
        }

        guard let password = buffer.getString(at: 10 + Int(nameLength), length: Int(passwordLength)) else {
            Log.error("failed to decode password")
            return nil
        }

        self.version = protocolVersion
        self.name = name
        self.password = password
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

        player.name = name

        Log.info("\(player): logged in")

        // login ok
        var buffer1 = ctx.channel.allocator.buffer(capacity: 4)
        buffer1.writeInteger(UInt16(2))
        buffer1.writeInteger(PacketType.loginOkPacket.rawValue)
        state.send(buffer: buffer1, channel: ctx.channel)

        // player count
        var buffer2 = ctx.channel.allocator.buffer(capacity: 6)
        buffer2.writeInteger(UInt16(4))
        buffer2.writeInteger(PacketType.playerCountPacket.rawValue)
        buffer2.writeInteger(UInt16(state.players.count))
        state.send(buffer: buffer2, channels: state.players.map{ (key, value) in
            return value.channel
        })

        // all games to the logged in player
        for (gameId, game) in state.games {
            let nameBytes: [UInt8] = Array(game.owner.name.utf8)
            let length = 2 + 4 + 2 + 2 + nameBytes.count
            var gameBuffer = ctx.channel.allocator.buffer(capacity: 2 + length)
            gameBuffer.writeInteger(UInt16(length))
            gameBuffer.writeInteger(PacketType.gameAddedPacket.rawValue)
            gameBuffer.writeInteger(UInt32(gameId))
            gameBuffer.writeInteger(game.scenarioId)
            gameBuffer.writeInteger(UInt16(nameBytes.count))
            gameBuffer.writeBytes(nameBytes)
            state.send(buffer: gameBuffer, channel: ctx.channel)
        }
    }
}
