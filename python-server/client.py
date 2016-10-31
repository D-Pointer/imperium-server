from struct import pack

from twisted.protocols.basic import Int16StringReceiver
import struct
from tcp_packet import TcpPacket
from statistics import Statistics
import resources
import definitions

class Client(Int16StringReceiver):

    nextId = 0

    def __init__ (self, clients, games, authManager):
        self.clients = clients
        self.games = games
        self.authManager = authManager
        self.id = Client.nextId
        Client.nextId += 1

        # not yet logged in
        self.loggedIn = False
        self.name = None

        # statistics
        self.statistics = Statistics()

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
            print "stringReceived: invalid packet type: %d" % packetType
            self.transport.loseConnection()
            return

        # call the handler
        try:
            self.handlers[ packetType ]( string )
        except:
            print "stringReceived: failed to execute handler for packet %d" % packetType
            self.transport.loseConnection()


    def handleLogin(self, data):
        offset = 0
        (packetType, protocol, nameLength) = struct.unpack_from( '!HHH', data, offset )
        offset += struct.calcsize('!HHH')

        if protocol != definitions.protocolVersion:
            print "handleLogin: invalid protocol: %d, our: %d" % (protocol, definitions.protocolVersion )
            self.send( TcpPacket.INVALID_PROTOCOL )
            self.transport.loseConnection()
            return

        # already logged in?
        if self.loggedIn:
            print "handleLogin: already logged in"
            self.send( TcpPacket.ALREADY_LOGGED_IN )
            return

        if nameLength == 0 or nameLength > 100:
            print "handleLogin: invalid name length: %d" % (nameLength)
            self.send( TcpPacket.INVALID_NAME )
            return

        # name
        (self.name, passwordLength) = struct.unpack_from( '!%dsH' % nameLength, data, offset )
        offset += struct.calcsize( '!%dsH' % nameLength )

        # TODO: name taken?

        if passwordLength == 0 or passwordLength > 100:
            print "handleLogin: invalid password length: %d" % (passwordLength)
            self.send( TcpPacket.INVALID_PASSWORD_PACKET )
            return

        # password
        (password, ) = struct.unpack_from( '!%ds' % passwordLength, data, offset )

        if not self.authManager.validatePassword( password ):
            print "handleLogin: invalid password"
            self.send( TcpPacket.INVALID_PASSWORD_PACKET )
            return

        # login ok
        self.send( TcpPacket.LOGIN_OK )

        self.loggedIn = True
        print "handleLogin: player %s logged in" % self.name

        # broadcast the changed player count
        self.broadcast( TcpPacket.PLAYER_COUNT_PACKET, struct.pack( '!H', len(self.clients)) )

        # TODO: send all games to this player


    def handleGetResource(self, data):
        offset = 0
        (packetType, nameLength) = struct.unpack_from( '!HH', data, offset )
        offset += struct.calcsize('!HH')

        if nameLength == 0 or nameLength > 1024:
            # invalid resource name length
            self.send( TcpPacket.INVALID_RESOURCE_NAME_PACKET )
            return

        # resource name
        (name, ) = struct.unpack_from( '%ds' % nameLength, data, offset )
        print "handleGetResource: name: '%s'" % name

        parts = resources.loadResource( name )
        if parts == None or len(parts) == 0:
            # invalid resource
            self.send( TcpPacket.INVALID_RESOURCE_PACKET )
            return

        # resource loaded ok, send off it in parts
        partIndex = 0
        partCount = len(parts)
        for part in parts:
            partLength = len(part)
            print "handleGetResource: part %d, length: %d, parts: %d" % (partIndex, partLength, partCount )
            self.send( TcpPacket.RESOURCE_PACKET, struct.pack( '!H%dsIBB' % nameLength, nameLength, name, len(part), partIndex, partCount ) )
            partIndex += 1


    def handleKeepAlivePacket(self, data):
        offset = 0
        (packetType, ) = struct.unpack_from( '!H', data, offset )
        offset += struct.calcsize('!H')
        print "handleKeepAlivePacket: TODO"


    def send (self, packetType, data=None):
        if data != None:
            dataLength = len(data)
            packetLength = struct.calcsize( '!H' ) + dataLength
            print "send: packet type: %s, data length: %d" % ( TcpPacket.name(packetType), dataLength)
            self.transport.write( struct.pack( '!HH', packetLength, packetType) )
            self.transport.write( data )

            self.statistics.tcpBytesSent += 2 + packetLength

        else:
            print "send: packet type: %s" % ( TcpPacket.name(packetType), )
            packetLength = struct.calcsize( '!H' )
            self.transport.write( struct.pack( '!HH', packetLength, packetType) )

        self.statistics.tcpBytesSent += 2 + packetLength
        self.statistics.tcpPacketsSent += 1



    def broadcast (self, packetType, data):
        """Send the packet to all clients."""
        dataLength = len(data)
        print "broadcast: packet type: %s, data length: %d" % ( TcpPacket.name(packetType), dataLength)
        for clientId, client in self.clients.iteritems():
            client.send( packetType, data )
