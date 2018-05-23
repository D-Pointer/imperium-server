import NIO
import Dispatch

final class ServerState {
    // All access to channels is guarded by channelsSyncQueue.
    let playersSyncQueue = DispatchQueue(label: "tcpQueue")

    var players: [ObjectIdentifier: Player] = [:]
    var playerLookup: [UInt32: Player] = [:]

    var games: [UInt32: Game] = [:]

    var mutex = Mutex()

    func send (buffer: ByteBuffer, channel: Channel) {
        debug(message: "send to one", bytes: buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes)!)

        playersSyncQueue.async {
            channel.writeAndFlush(buffer, promise: nil)
        }
    }

    func send (buffer: ByteBuffer, channels: [Channel]) {
        debug(message: "broadcast", bytes: buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes)!)

        playersSyncQueue.async {
            channels.forEach{ channel in
                channel.writeAndFlush(buffer, promise: nil)
            }
        }
    }

    func send (buffer: ByteBuffer, channels: [ObjectIdentifier: Channel]) {
        debug(message: "send to many", bytes: buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes)!)

        playersSyncQueue.async {
            channels.forEach { $0.value.writeAndFlush(buffer, promise: nil) }
        }
    }

    private func debug(message: String, bytes: [UInt8]) {
        let byteString = bytes.reduce("", { (result, byte) in
            return result + String(format:"%02X ", byte)
        })

        Log.debug("\(message), bytes: [\(byteString)]")
    }
}

