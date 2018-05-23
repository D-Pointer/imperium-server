
import NIO

enum DecodingException : Error {
    case invalidData
}

final class PacketCodec: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Packet

    var cumulationBuffer: ByteBuffer?

    let factory = PacketFactory()

    func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let length = buffer.getInteger(at: 0, endianness: .big, as: UInt16.self) else {
            return .needMoreData
        }

        // do we have enough data for the content?
        if buffer.readableBytes < length + 2 {
            return .needMoreData
        }

        guard let packet = factory.createPacket(buffer: buffer) else {
            Log.error("invalid packet data")
            throw DecodingException.invalidData
        }

        // consume the bytes
        _ = buffer.readSlice(length: 2 + Int(length))
        ctx.fireChannelRead(self.wrapInboundOut(packet))
        return .continue
    }
}
