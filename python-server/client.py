
from twisted.protocols.basic import Int16StringReceiver
import struct
import datetime

from tcp_packet import TcpPacket
from statistics import Statistics
import resources
import definitions
from game import Game
from udp_handler import UdpHandler

class Client(Int16StringReceiver):

    nextId = 0

    def __init__ (self, clients, games, authManager):
        self.id = Client.nextId
        Client.nextId += 1

        self.clients = clients
        self.games = games
        self.authManager = authManager

        # not yet logged in
        self.loggedIn = False
        self.name = None

        # no own game yet
        self.game = None

        # not ready to start yet
        self.readyToStart = False

        # no UDP handler yet connected to the client
        self.udpHandler = None

        # statistics
        self.statistics = Statistics()

        # set up the handlers
        self.handlers = {
            TcpPacket.LOGIN: self.handleLogin,
            TcpPacket.ANNOUNCE: self.handleAnnounce,
            TcpPacket.LEAVE_GAME: self.handleLeave,
            TcpPacket.JOIN_GAME: self.handleJoin,
            TcpPacket.DATA: self.handleData,
            TcpPacket.READY_TO_START: self.handleReadyToStart,
            TcpPacket.GET_RESOURCE_PACKET: self.handleGetResource,
            TcpPacket.KEEPALIVE_PACKET: self.handleKeepAlivePacket,
        }


    def connectionMade(self):
        self.clients[ self.id ] = self

        remotePeer = self.transport.getPeer()
        print "connectionMade: client from: %s:%d, clients now: %d" % ( remotePeer.host, remotePeer.port, len(self.clients) )

        self.statistics.connected = datetime.datetime.now()


    def connectionLost(self, reason):
        if self.id in self.clients:
            del self.clients[ self.id ]

        print "connectionLost: clients left: %d" % len(self.clients)

        self.game = None
        if self.udpHandler:
            self.udpHandler.cleanup()


    def stringReceived(self, string):
        # get the first byte, the packet type
        (packetType, ) = struct.unpack_from( '!H', string, 0 )
        print "stringReceived: packet type: %d, name: %s, bytes: %d" % (packetType, TcpPacket.name(packetType), len(string))

        # find a handler to handle the real packet
        if not self.handlers.has_key( packetType ):
            print "stringReceived: invalid packet type: %d" % packetType
            self.transport.loseConnection()
            return

        # call the handler
        try:
            # call the handler, and strip out the first 2 bytes: the packet type
            self.handlers[ packetType ]( string[2:] )

            # update statistics
            self.statistics.tcpBytesReceived += len(string)
            self.statistics.tcpPacketsReceived += 1
            self.statistics.tcpLastR = datetime.datetime.now()
        except:
            print "stringReceived: failed to execute handler for packet %d" % packetType
            self.transport.loseConnection()
            raise


    def handleLogin(self, data):
        offset = 0
        (protocol, nameLength) = struct.unpack_from( '!HHH', data, offset )
        offset += struct.calcsize('!HH')

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

        # name taken?
        for player in self.clients.values():
            if player != self and player.name == name:
                self.send( TcpPacket.NAME_TAKEN )
                return

        # password
        if passwordLength == 0 or passwordLength > 100:
            print "handleLogin: invalid password length: %d" % (passwordLength)
            self.send( TcpPacket.INVALID_PASSWORD_PACKET )
            return

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


    def handleAnnounce (self, data):
        # do we already have a game?
        if self.game:
            print "handleAnnounce: alread have a game"
            self.send( TcpPacket.ALREADY_ANNOUNCED )
            return

        offset = 0
        (scenarioId, ) = struct.unpack_from( '!H', data, offset )
        offset += struct.calcsize('!HH')

        # set up the game
        self.game = Game( self, scenarioId )
        self.games[ self.game.id ] = self.game
        print "handleAnnounce: announced game %d, scenario: %d" % (self.game.id, self.game.scenarioId)

        # send the game to the client
        self.send( TcpPacket.ANNOUNCE_OK, struct.pack( '!I', self.game.id) )

        # broadcast the added game to all players
        self.broadcast( TcpPacket.GAME_ADDED, struct.pack( '!IHH%ds' % len(self.name), self.game.id, self.game.scenarioId, len(self.name), self.name ) )


    def handleJoin (self, data):
        # do we have a game?
        if self.game:
            print "handleJoin: already has a game, can not join another"
            self.send( TcpPacket.ALREADY_HAS_GAME )
            return

        # joined game
        (gameId, ) = struct.unpack_from( '!I', data, 0 )
        if not self.games.has_key( gameId ):
            print "handleJoin: no such game: %d" % gameId
            self.send( TcpPacket.INVALID_GAME )
            return

        game = self.games[ gameId ]

        # game already full?
        if game.hasStarted():
            print "handleJoin: game has already started, can not join"
            self.send( TcpPacket.GAME_FULL )
            return

        # game is ok and it's ours
        game.player2 = self
        self.game = game

        opponent = game.player1

        # set up UDP handlers
        self.udpHandler = UdpHandler()
        opponent.udpHandler = UdpHandler()

        # the opponent is player 1, send its UDP port and our name
        dataTo1 = struct.pack( '!HH%ds' % len(self.name), opponent.udpHandler.getLocalPort(), len(self.name), self.name )
        opponent.send( TcpPacket.GAME_JOINED, dataTo1 )

        # send the opponent data to us, along with our UDP port
        dataTo2 = struct.pack( '!HH%ds' % len(opponent.name), self.udpHandler.getLocalPort(), len(opponent.name), opponent.name )
        self.send( TcpPacket.GAME_JOINED, dataTo2 )

        # the game is no longer open, tell everyone
        self.broadcast( TcpPacket.GAME_REMOVED, struct.pack( '!I', self.game.id ) )


    def handleLeave (self, data):
        # do we have a game?
        if not self.game:
            print "handleLeave: no game, nothing to leave"
            self.send( TcpPacket.NO_GAME )
            return

        print "handleLeave: leaving game %d, scenario: %d" % (self.game.id, self.game.scenarioId)

        self.game.endGame()

        # has it started?
        if self.game.hasStarted():
            # notify the opponent and clear
            opponent = self.game.getOpponent()
            if opponent:
                opponent.send( TcpPacket.GAME_ENDED )
                opponent.game = None

            # notify and clear our game
            self.send( TcpPacket.GAME_ENDED )
            del( self.games[ self.game.id ] )
            self.game = None

        else:
            # not started, so it's still looking for players, broadcast the removal to all players
            self.broadcast( TcpPacket.GAME_REMOVED, struct.pack( '!I', self.game.id ) )


    def handleData (self, data):
        if self.game == None:
            print "handleData: no game, can not send data"
            return

        opponent = self.game.getOpponent()
        if opponent:
            print "handleData: sending %d bytes to opponent" % len(data)
            opponent.send( TcpPacket.DATA, data )
        else:
            print "handleData: no opponent, can not send data"


    def handleReadyToStart (self, data):
        if self.game == None:
            print "handleReadyToStart: no game, can not handle ready to start"
            self.send( TcpPacket.NO_GAME )
            return

        opponent = self.game.getOpponent( self )
        if opponent == None:
            print "handleReadyToStart: no opponent, can not handle ready to start"
            self.send( TcpPacket.INVALID_GAME )
            return

        # we're now ready to start
        self.readyToStart = True

        # is the opponent also ready to start?
        if opponent.readyToStart:
            print "handleReadyToStart: opponent also ready to start, sending start packets"
            self.udpHandler.sendStartPackets()


    def handleGetResource(self, data):
        offset = 0
        (nameLength, ) = struct.unpack_from( '!H', data, offset )
        offset += struct.calcsize('!H')

        if nameLength == 0 or nameLength > 1024:
            # invalid resource name length
            self.send( TcpPacket.INVALID_RESOURCE_NAME_PACKET )
            return

        # resource name
        (name, ) = struct.unpack_from( '!%ds' % nameLength, data, offset )
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
        print "handleKeepAlivePacket: TODO"


    def broadcast (self, packetType, data):
        """Send the packet to all clients."""
        dataLength = len(data)
        print "broadcast: packet type: %s, data length: %d" % ( TcpPacket.name(packetType), dataLength)
        for clientId, client in self.clients.iteritems():
            client.send( packetType, data )


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
        self.statistics.tcpLastSent = datetime.datetime.now()
