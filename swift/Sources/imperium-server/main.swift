
import NIO
import CoreFoundation

func main() throws {
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

    Log.debug("cores: \(System.coreCount)")

    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
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
        // when done, shut down
        try! group.syncShutdownGracefully()
    }


    let udpBootstrap = DatagramBootstrap(group: group)
        // Enable SO_REUSEADDR.
        .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .channelInitializer { channel in
            channel.pipeline.add(handler: UdpPacketHandler(serverState: serverState, factory: UdpPacketFactory()))
    }

    let udpChannel = try udpBootstrap.bind(host: host, port: 12000).wait()

    guard let localUdpAddress = udpChannel.localAddress else {
        fatalError("UDP address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }


    let channel = try { () -> Channel in
        return try bootstrap.bind(host: host, port: port).wait()
        }()

    guard let localAddress = channel.localAddress else {
        fatalError("TCP address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
    }

    Log.info("Imperium server \(VERSION_STRING) started, listening on TCP: \(localAddress) and UDP: \(localUdpAddress)")

    // This will never unblock as we don't close the ServerChannel.
    try _ = udpChannel.closeFuture.and(channel.closeFuture).wait()
    //try udpChannel.closeFuture.wait()  // Wait until the channel un-binds.

    Log.info("Imperium server closed")
}

// run the main application loop
do {
    try main()
}
catch {
    fatalError("Server error: \(error)")
}
