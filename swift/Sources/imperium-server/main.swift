
import NIO
import CoreFoundation

private let newLine = "\n".utf8.first!

//extension ByteBuffer {
//    func getUInt16(at offset: Int) -> UInt16? {
//        if offset > readableBytes - 2 {
//            return nil
//        }
//
//        guard let bytes = self.getBytes(at: readerIndex + offset, length: 2) else {
//            return nil
//        }
//
//        let value = UnsafePointer(bytes).withMemoryRebound(to: UInt16.self, capacity: 1) {
//            $0.pointee
//        }
//
//        return CFSwapInt16(value)
//    }
//}



/// Very simple example codec which will buffer inbound data until a `\n` was found.
/*final class LineDelimiterCodec: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ByteBuffer

    public var cumulationBuffer: ByteBuffer?

    public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        let readable = buffer.withUnsafeReadableBytes { $0.index(of: newLine) }
        if let r = readable {
            ctx.fireChannelRead(self.wrapInboundOut(buffer.readSlice(length: r + 1)!))
            return .continue
        }
        return .needMoreData
    }
}*/


/// This `ChannelInboundHandler` demonstrates a few things:
///   * Synchronisation between `EventLoop`s.
///   * Mixing `Dispatch` and SwiftNIO.
///   * `Channel`s are thread-safe, `ChannelHandlerContext`s are not.
///
/// As we are using an `MultiThreadedEventLoopGroup` that uses more then 1 thread we need to ensure proper
/// synchronization on the shared state in the `ChatHandler` (as the same instance is shared across
/// child `Channel`s). For this a serial `DispatchQueue` is used when we modify the shared state (the `Dictionary`).
/// As `ChannelHandlerContext` is not thread-safe we need to ensure we only operate on the `Channel` itself while
/// `Dispatch` executed the submitted block.
/*final class ChatHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    // All access to channels is guarded by channelsSyncQueue.
    private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
    private var channels: [ObjectIdentifier: Channel] = [:]

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let id = ObjectIdentifier(ctx.channel)
        var read = self.unwrapInboundIn(data)

        // 64 should be good enough for the ipaddress
        var buffer = ctx.channel.allocator.buffer(capacity: read.readableBytes + 64)
        buffer.write(string: "(\(ctx.remoteAddress!)) - ")
        buffer.write(buffer: &read)
        self.channelsSyncQueue.async {
            // broadcast the message to all the connected clients except the one that wrote it.
            self.writeToAll(channels: self.channels.filter { id != $0.key }, buffer: buffer)
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        ctx.close(promise: nil)
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        let remoteAddress = ctx.remoteAddress!
        let channel = ctx.channel
        self.channelsSyncQueue.async {
            // broadcast the message to all the connected clients except the one that just became active.
            self.writeToAll(channels: self.channels, allocator: channel.allocator, message: "(ChatServer) - New client connected with address: \(remoteAddress)\n")

            self.channels[ObjectIdentifier(channel)] = channel
        }

        var buffer = channel.allocator.buffer(capacity: 64)
        buffer.write(string: "(ChatServer) - Welcome to: \(ctx.localAddress!)\n")
        ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }

    public func channelInactive(ctx: ChannelHandlerContext) {
        let channel = ctx.channel
        self.channelsSyncQueue.async {
            if self.channels.removeValue(forKey: ObjectIdentifier(channel)) != nil {
                // Broadcast the message to all the connected clients except the one that just was disconnected.
                self.writeToAll(channels: self.channels, allocator: channel.allocator, message: "(ChatServer) - Client disconnected\n")
            }
        }
    }

    private func writeToAll(channels: [ObjectIdentifier: Channel], allocator: ByteBufferAllocator, message: String) {
        var buffer =  allocator.buffer(capacity: message.utf8.count)
        buffer.write(string: message)
        self.writeToAll(channels: channels, buffer: buffer)
    }

    private func writeToAll(channels: [ObjectIdentifier: Channel], buffer: ByteBuffer) {
        channels.forEach { $0.value.writeAndFlush(buffer, promise: nil) }
    }
}*/

func mainLoop() throws {
    // First argument is the program path
    let arguments = CommandLine.arguments
    if arguments.count != 3 {
        Log.error("Invalid arguments, usage: \(arguments.first!) host port")
        return
    }

    let host = arguments.dropFirst().first!
    guard let port = Int(arguments.dropFirst(2).first!) else {
        Log.error("invalid port")
        return
    }

    let serverState = ServerState()

    // We need to share the same PacketHandler for all as it keeps track of all
    // connected players. For this PacketHandler MUST be thread-safe!
    let packetHandler = PacketHandler(serverState: serverState)

    let group = MultiThreadedEventLoopGroup(numThreads: System.coreCount)
    let bootstrap = ServerBootstrap(group: group)
        // Specify backlog and enable SO_REUSEADDR for the server itself
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

        // Set the handlers that are applied to the accepted Channels
        .childChannelInitializer { channel in
            // a codec that can read the incoming packets
            channel.pipeline.add(handler: PacketCodec()).then { v in
                // Its important we use the same handler for all accepted channels. The packet handler is thread-safe!
                channel.pipeline.add(handler: packetHandler)
            }
        }

        // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    defer {
        try! group.syncShutdownGracefully()
    }


    let udpBootstrap = DatagramBootstrap(group: group)
        // Enable SO_REUSEADDR.
        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .channelInitializer { channel in
            channel.pipeline.add(handler: UdpPacketHandler(serverState: serverState, factory: UdpPacketFactory()))
    }

    let udpChannel = try! udpBootstrap.bind(host: host, port: 12000).wait()

    guard let localUdpAddress = udpChannel.localAddress else {
        fatalError("UDP address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }


    let channel = try { () -> Channel in
        return try bootstrap.bind(host: host, port: port).wait()
        }()

    guard let localAddress = channel.localAddress else {
        fatalError("TCP address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }

    Log.info("Server started and listening on \(localAddress) and \(localUdpAddress)")

    // This will never unblock as we don't close the ServerChannel.
    try udpChannel.closeFuture.and(channel.closeFuture).wait()
    //try udpChannel.closeFuture.wait()  // Wait until the channel un-binds.

    Log.info("ChatServer closed")
}

// run the main application loop
try mainLoop()
