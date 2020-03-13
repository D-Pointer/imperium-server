
import NIO

final class ProtobufPacketCodec: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Packet

    var cumulationBuffer: ByteBuffer?

    let factory = PacketFactory()

    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
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
        context.fireChannelRead(self.wrapInboundOut(packet))
        return .continue
    }

    func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws  -> DecodingState {
        return try decode(context: context, buffer: &buffer)
    }

}
