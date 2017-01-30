
from twisted.protocols.basic import Int16StringReceiver
import struct
import datetime
import logging

from tcp_packet import TcpPacket
from statistics import Statistics
import resources
import definitions
from game import Game
from udp_handler import UdpHandler

class Client(Int16StringReceiver):

    nextId = 0

    def __init__ (self, clients, games, authManager, reactor):
        self.id = Client.nextId
        Client.nextId += 1

        self.logger = logging.getLogger( "client-%d" % self.id )
        self.logger.info( "client initialized" )

        self.clients = clients
        self.games = games
        self.authManager = authManager
        self.reactor = reactor

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
            TcpPacket.KEEP_ALIVE_PACKET: self.handleKeepAlivePacket,
        }


    def connectionMade(self):
        self.clients[ self.id ] = self

        remotePeer = self.transport.getPeer()
        self.logger.info("client from: %s:%d, clients now: %d" % ( remotePeer.host, remotePeer.port, len(self.clients) ) )

        self.statistics.connected = datetime.datetime.now()


    def connectionLost(self, reason):
        if self.id in self.clients:
            del self.clients[ self.id ]

        self.logger.info( "client disconnected, now left %d", len(self.clients) )

        # do we have a game?
        if self.game and self.game.hasStarted():
            self.logger.debug( "writing game statistics" )
            self.game.ended = datetime.datetime.now()
            self.saveStatistics()

        # back to old logger
        self.logger = logging.getLogger( "client-%d" % self.id )

        self.game = None
        if self.udpHandler:
            self.udpHandler.cleanup()


    def stringReceived(self, string):
        # get the first byte, the packet type
        #self.logger.debug( "stringReceived: bytes: %d", len(string) )
        (packetType, ) = struct.unpack_from( '!H', string, 0 )
        self.logger.debug( "received packet type: %d, name: %s", packetType, TcpPacket.name(packetType) )

        # find a handler to handle the real packet
        if not self.handlers.has_key( packetType ):
            self.logger.error( "received invalid packet type: %d", packetType )
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
            self.logger.error( "failed to execute handler for packet %d", packetType )
            self.transport.loseConnection()
            raise


    def handleLogin(self, data):
        offset = 0
        (protocol, nameLength) = struct.unpack_from( '!HH', data, offset )
        offset += struct.calcsize('!HH')

        if protocol != definitions.protocolVersion:
            self.logger.warn( "invalid protocol: %d, our: %d", protocol, definitions.protocolVersion )
            self.send( TcpPacket.INVALID_PROTOCOL )
            self.transport.loseConnection()
            return

        # already logged in?
        if self.loggedIn:
            self.logger.warn( "already logged in" )
            self.send( TcpPacket.ALREADY_LOGGED_IN )
            return

        if nameLength == 0 or nameLength > 100:
            self.logger.warn( "invalid name length: %d", nameLength)
            self.send( TcpPacket.INVALID_NAME )
            return

        # name
        (self.name, passwordLength) = struct.unpack_from( '!%dsH' % nameLength, data, offset )
        offset += struct.calcsize( '!%dsH' % nameLength )

        # name taken?
        for player in self.clients.values():
            if player != self and player.name == self.name:
                self.send( TcpPacket.NAME_TAKEN )
                return

        # password
        if passwordLength == 0 or passwordLength > 100:
            self.logger.warn( "invalid password length: %d", passwordLength )
            self.send( TcpPacket.INVALID_PASSWORD_PACKET )
            return

        (password, ) = struct.unpack_from( '!%ds' % passwordLength, data, offset )

        if not self.authManager.validatePassword( password ):
            self.logger.warn( "invalid password" )
            self.send( TcpPacket.INVALID_PASSWORD_PACKET )
            return

        # login ok
        self.send( TcpPacket.LOGIN_OK )

        self.loggedIn = True
        self.logger.info( "player %s logged in", self.name )

        # broadcast the changed player count
        self.broadcast( TcpPacket.PLAYER_COUNT_PACKET, struct.pack( '!H', len(self.clients)) )

        # send all games to this player
        for gameId, game in self.games.iteritems():
            ownerName = game.player1.name
            data = struct.pack( '!IHH%ds' % len(ownerName), gameId, game.scenarioId, len(ownerName), ownerName )
            self.send( TcpPacket.GAME_ADDED, data )


    def handleAnnounce (self, data):
        # do we already have a game?
        if self.game:
            self.logger.warn( "alread have a game, can not announce another" )
            self.send( TcpPacket.ALREADY_ANNOUNCED )
            return

        offset = 0
        (scenarioId, ) = struct.unpack_from( '!H', data, offset )
        offset += struct.calcsize('!HH')

        # set up the game
        self.game = Game( self, scenarioId )
        self.games[ self.game.id ] = self.game
        self.logger.info( "announced game %d, scenario: %d", self.game.id, self.game.scenarioId )

        # new game logger
        self.logger = logging.getLogger( "client-%d-%d" % (self.id, self.game.id ) )

        # send the game to the client
        self.send( TcpPacket.ANNOUNCE_OK, struct.pack( '!I', self.game.id) )

        # broadcast the added game to all players
        self.broadcast( TcpPacket.GAME_ADDED, struct.pack( '!IHH%ds' % len(self.name), self.game.id, self.game.scenarioId, len(self.name), self.name ) )


    def handleJoin (self, data):
        # do we have a game?
        if self.game:
            self.logger.warn( "already have a game, can not join another" )
            self.send( TcpPacket.ALREADY_HAS_GAME )
            return

        # joined game
        (gameId, ) = struct.unpack_from( '!I', data, 0 )
        if not self.games.has_key( gameId ):
            self.logger.warn( "no such game: %d", gameId )
            self.send( TcpPacket.INVALID_GAME )
            return

        game = self.games[ gameId ]

        # game already full?
        if game.hasStarted():
            self.logger.warn( "game has already started, can not join" )
            self.send( TcpPacket.GAME_FULL )
            return

        # game is ok and it's ours
        game.player2 = self
        self.game = game

        opponent = game.player1

        # set up UDP handlers
        self.udpHandler = UdpHandler( self.statistics, self.logger, self.reactor )
        opponent.udpHandler = UdpHandler( opponent.statistics, self.logger, self.reactor )

        # let the UDP handlers know about each other
        self.udpHandler.opponent = opponent
        opponent.opponent = self.udpHandler

        # the opponent is player 1, send its UDP port and our name
        dataTo1 = struct.pack( '!HH%ds' % len(self.name), opponent.udpHandler.getLocalPort(), len(self.name), self.name )
        opponent.send( TcpPacket.GAME_JOINED, dataTo1 )

        # send the opponent data to us, along with our UDP port
        dataTo2 = struct.pack( '!HH%ds' % len(opponent.name), self.udpHandler.getLocalPort(), len(opponent.name), opponent.name )
        self.send( TcpPacket.GAME_JOINED, dataTo2 )

        # the game is no longer open, tell everyone
        self.broadcast( TcpPacket.GAME_REMOVED, struct.pack( '!I', self.game.id ) )

        self.logger.info( "joined game %d with opponent %d", self.game.id, self.game.player1.id )


    def handleLeave (self, data):
        # do we have a game?
        if not self.game:
            self.logger.warn( "no game, nothing to leave" )
            self.send( TcpPacket.NO_GAME )
            return

        self.logger.info( "leaving game %d, scenario: %d", self.game.id, self.game.scenarioId )

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

            # back to old logger
            self.logger = logging.getLogger( "client-%d" % self.id )

        else:
            # not started, so it's still looking for players, broadcast the removal to all players
            self.broadcast( TcpPacket.GAME_REMOVED, struct.pack( '!I', self.game.id ) )


    def handleData (self, data):
        if self.game == None:
            self.logger.warn( "no game, can not send data" )
            return

        opponent = self.game.getOpponent()
        if opponent:
            self.logger.debug( "sending %d bytes to opponent", len(data) )
            opponent.send( TcpPacket.DATA, data )
        else:
            self.logger.warn( "no opponent, can not send data" )


    def handleReadyToStart (self, data):
        if self.game == None:
            self.logger.warn( "no game, can not handle ready to start" )
            self.send( TcpPacket.NO_GAME )
            return

        opponent = self.game.getOpponent( self )
        if opponent == None:
            self.logger.warn( "no opponent, can not handle ready to start" )
            self.send( TcpPacket.INVALID_GAME )
            return

        # we're now ready to start
        self.readyToStart = True

        # is the opponent also ready to start?
        if opponent.readyToStart:
            self.logger.debug( "handleReadyToStart: opponent also ready to start, sending start packets" )
            self.udpHandler.sendStartPackets()

            # the game has started now
            self.game.started = datetime.datetime.now()


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
        self.logger.debug( "sending resource: '%s'", name )

        totalLength, parts = resources.loadResource( name, self.logger )
        if parts == None or len(parts) == 0:
            # invalid resource
            self.send( TcpPacket.INVALID_RESOURCE_PACKET )
            return

        # resource loaded ok, send off it in parts
        partIndex = 0
        partCount = len(parts)
        for part in parts:
            partLength = len(part)
            self.logger.debug( "part %d, length: %d, parts: %d", partIndex, partLength, partCount )
            self.send( TcpPacket.RESOURCE_PACKET, struct.pack( '!H%dsIBBH%ds' % (nameLength, partLength), nameLength, name, totalLength, partIndex, partCount, partLength, part ) )
            partIndex += 1


    def handleKeepAlivePacket(self, data):
        self.logger.debug( "TODO: keep alive" )


    def broadcast (self, packetType, data):
        """Send the packet to all clients."""
        dataLength = len(data)
        self.logger.debug( "broadcasting packet of type: %s, data length: %d to %d players", TcpPacket.name(packetType), dataLength, len(self.clients) )
        for clientId, client in self.clients.iteritems():
            client.send( packetType, data )


    def send (self, packetType, data=None):
        packetLength = 0

        if data != None:
            dataLength = len(data)
            packetLength = struct.calcsize( '!H' ) + dataLength
            self.logger.debug( "sending packet of type: %s, data length: %d", TcpPacket.name(packetType), dataLength)
            self.transport.write( struct.pack( '!HH', packetLength, packetType) )
            self.transport.write( data )

        else:
            self.logger.debug( "sending empty packet of type: %s", TcpPacket.name(packetType) )
            packetLength = struct.calcsize( '!H' )
            self.transport.write( struct.pack( '!HH', packetLength, packetType) )

        self.statistics.lock()
        self.statistics.tcpPacketsSent += 1
        self.statistics.tcpBytesSent += 2 + packetLength
        self.statistics.tcpLastSent = datetime.datetime.now()
        self.statistics.release()


    def saveStatistics (self):
        if not self.game:
            self.logger.warning( "no game, can not save statistics" )
            return

        # are we player 1? only the first player saves the statistics
        if self.game.player1 != self:
            # not player 1
            return

        filename = 'games/%d.txt' % self.game.id

        try:
            file = open( filename, 'w')
            file.write( 'game %d\n' % self.game.id )
            file.write( 'scenario %d\n' % self.game.scenarioId )
            file.write( 'created %s\n' % self.game.created.isoformat( ' '))

            if self.game.started:
                file.write('started %s\n' % self.game.started.isoformat(' '))
            else:
                file.write('started -\n')

            if self.game.ended:
                file.write('ended %s\n' % self.game.ended.isoformat(' '))
                file.write('duration %d\n' % (self.game.ended - self.game.started).seconds )
            else:
                file.write('ended -\n')
                file.write('duration -\n')

            file.write( 'player1 %s\n' % self.game.player1.name )
            file.write( 'player2 %s\n' % self.game.player2.name )

            # player 1 stats
            stats1 = self.game.player1.statistics
            stats2 = self.game.player2.statistics
            file.write('tcpPacketsSent %d %d\n' % (stats1.tcpPacketsSent, stats2.tcpPacketsSent ))
            file.write('tcpBytesSent %d %d\n' % (stats1.tcpBytesSent, stats2.tcpBytesSent ))
            file.write('tcpLastSent %d %d\n' % (stats1.tcpLastSent, stats2.tcpLastSent ))
            file.write('tcpPacketsReceived %d %d\n' % (stats1.tcpPacketsReceived, stats2.tcpPacketsReceived ))
            file.write('tcpBytesReceived %d %d\n' % (stats1.tcpBytesReceived, stats2.tcpBytesReceived ))
            file.write('tcpLastReceived %d %d\n' % (stats1.tcpLastReceived, stats2.tcpLastReceived ))
            file.write('udpPacketsSent %d %d\n' % (stats1.udpPacketsSent, stats2.udpPacketsSent ))
            file.write('udpBytesSent %d %d\n' % (stats1.udpBytesSent, stats2.udpBytesSent ))
            file.write('udpLastSent %d %d\n' % (stats1.udpLastSent, stats2.udpLastSent ))
            file.write('udpPacketsReceived %d %d\n' % (stats1.udpPacketsReceived, stats2.udpPacketsReceived ))
            file.write('udpBytesReceived %d %d\n' % (stats1.udpBytesReceived, stats2.udpBytesReceived ))
            file.write('udpLastReceived %d %d\n' % (stats1.udpLastReceived, stats2.udpLastReceived ))

        except OSError:
            self.logger.error( "failed to write to statistics file: %s", filename )
