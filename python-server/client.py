from twisted.protocols.basic import Int16StringReceiver
import struct
from tcp_packet import TcpPacket

class Client(Int16StringReceiver):

    nextId = 0

    def __init__ (self, clients):
        self.clients = clients
        self.id = Client.nextId
        Client.nextId += 1

        # set up the handlers
        self.handlers = {
            TcpPacket.LOGIN: self.handleLogin,
            TcpPacket.ANNOUNCE: self.handleLogin,
            TcpPacket.LEAVE_GAME: self.handleLogin,
            TcpPacket.JOIN_GAME: self.handleLogin,
            TcpPacket.DATA: self.handleLogin,
            TcpPacket.READY_TO_START: self.handleLogin,
            TcpPacket.GET_RESOURCE_PACKET: self.handleGetResource,
            TcpPacket.KEEPALIVE_PACKET: self.handleKeepAlivePacket,
        }

    def connectionMade(self):
        self.clients[ self.id ] = self
        print "connectionMade: clients now: %d" % len(self.clients)

        # self.factory was set by the factory's default buildProtocol:
        #self.transport.write( 'Hello world!\r\n')


    def connectionLost(self, reason):
        if self.id in self.clients:
            del self.clients[ self.id ]

        print "connectionLost: clients left: %d" % len(self.clients)


    def stringReceived(self, string):
        # get the first byte, the packet type
        (packetType, ) = struct.unpack_from( '!H', string, 0 )
        print "stringReceived: packet type: %d, name: %s" % (packetType, TcpPacket.name(packetType))

        # find a handler to handle the real packet
        if not self.handlers.has_key( packetType ):
            print "invalid packet type: %d" % packetType
            self.transport.loseConnection()
            return

        # call the handler
        self.handlers[ packetType ]( string )


    def handleLogin(self, data):
        offset = 0
        (packetType, protocol, nameLength) = struct.unpack_from( '!HHH', data, offset )
        offset += struct.calcsize('!HHH')
        print "handleLogin: protocol: %d" % protocol

        # name
        (name, passwordLength) = struct.unpack_from( '!%dsH' % nameLength, data, offset )
        offset += struct.calcsize( '%dsH' % nameLength )
        print "handleLogin: name: '%s'" % name

        # password
        (password) = struct.unpack_from( '!%ds' % passwordLength, data, offset )
        print "handleLogin: password: '%s'" % password


    def handleGetResource(self, data):
        offset = 0
        (packetType, resourceNameLength) = struct.unpack_from( '!HH', data, offset )
        offset += struct.calcsize('!HH')

        # resource name
        (resourceName, ) = struct.unpack_from( '%ds' % resourceNameLength, data, offset )
        print "handleGetResource: name: '%s'" % resourceName


    def handleKeepAlivePacket(self, data):
        offset = 0
        (packetType, ) = struct.unpack_from( '!H', data, offset )
        offset += struct.calcsize('!H')
        print "handleKeepAlivePacket"