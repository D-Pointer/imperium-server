import logging
import asyncore
import socket
import struct

from packet         import Packet, name

class PlayerHandler(asyncore.dispatcher_with_send):

    handlerId = 0

    def __init__ (self, sock, playerManager, gameManager):
        asyncore.dispatcher_with_send.__init__(self, sock)
        self.logger = logging.getLogger('PlayerHandler-%d' % PlayerHandler.handlerId)
        PlayerHandler.handlerId += 1

        self.clientVersion = -1
        self.clientName = ''
        self.data = ''

        self.playerManager = playerManager
        self.gameManager = gameManager

        # our game that we're announing or in
        self.game = None


    def handle_read(self):
        try:
            data = self.recv(8192)
        except socket.error:
            self.logger.debug('handle_read: failed to receive data')
            return

        if not data:
            #self.logger.debug('handle_read: no data received')
            return

        # append the data to our internal buffer
        self.data += data

        while len( self.data ) > 0:
            #self.logger.debug('handle_read: data length: %d bytes', len(self.data) )

            # can we read a header?
            if len(self.data) < Packet.headerLength:
                self.logger.debug('handle_read: can not read full header' )
                return

            # get the packet length
            (packetLength, packetType) = Packet.parseHeader( self.data )
            self.logger.debug('handle_read: packet: %s, length: %d bytes', name( packetType ), packetLength )

            # can we read the rest of the packet?
            if len(self.data) < packetLength:
                self.logger.debug('handle_read: can not read full packet' )
                return

            # handle the packet
            payloadLength = self.handlePacket( packetType, self.data[ Packet.headerLength:Packet.headerLength + packetLength ] )

            # strip off the handled packet
            self.data = self.data[ Packet.headerLength + payloadLength: ]


    def handle_close(self):
        self.close()

        if self.playerManager.removePlayer( self ):
            self.logger.debug('handle_close: player removed, now %d players' % self.playerManager.getPlayerCount() )
        else:
            self.logger.warning('handle_close: self not found among players!')

        # do we have a game?
        if self.game is not None:
            self.logger.debug('handle_close: ending game %s' % self.game )
            data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.ENDS, self.game.gameId )

            if self.game.player1 is not None and self.game.player1 != self:
                # player 1 is the connected opponent
                self.game.player1.send( data )
                self.game.player1.game = None

            elif self.game.player2 is not None and self.game.player2 != self:
                # player 2 is the connected opponent
                self.game.player2.send( data )
                self.game.player2.game = None

            self.game.cleanup()
            self.game = None


    def handlePacket (self, packetType, data):
        if packetType == Packet.INFO:
            return self.handleInfoPacket( data )

        elif packetType == Packet.ANNOUNCE:
            return self.handleAnnouncePacket( data )

        elif packetType == Packet.JOIN:
            return self.handleJoinPacket( data )

        elif packetType == Packet.LEAVE:
            return self.handleLeavePacket( data )

        elif packetType == Packet.GET_GAMES:
            return self.handleGetGamesPacket( data )

        elif packetType == Packet.GET_PLAYERS:
            return self.handleGetPlayersPacket( data )

        elif packetType == Packet.PING:
            return self.handlePingPacket( data )

        elif packetType == Packet.DATA:
            return self.handleDataPacket( data )

        else:
            self.logger.error( 'handlePacket: unknown packet type: %d', packetType )

        return 0


    def handleInfoPacket (self, data):
        (self.clientVersion, nameLength) = struct.unpack_from( '>Ih', data, 0 )
        (self.clientName, ) = struct.unpack_from( '>%ds' % nameLength, data, struct.calcsize('>Ih') )
        self.logger.debug('handleInfoPacket: client joined, name: %s, version: %d', self.clientName, self.clientVersion )
        return struct.calcsize( '>Ih' ) + len(self.clientName)


    def handleAnnouncePacket (self, data):
        # do we already have a game?
        if self.game is not None:
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return Packet.shortLength

        (scenarioId, ) = struct.unpack_from( '>h', data, 0 )

        # create a new announced game
        self.game = self.gameManager.createGame( scenarioId, self )
        self.gameManager.addGame( self.game )
        self.logger.debug('handleAnnouncePacket: announce game: %d with scenario: %d', self.game.gameId, self.game.scenarioId )
        self.logger.debug('handleAnnouncePacket: announced games now: %d', len( self.gameManager.getAnnouncedGames() ) )

        # send the game as a response
        length = struct.calcsize( '>hhh' )
        data = struct.pack( '>hhhh', length, Packet.GAME, self.game.gameId, self.game.scenarioId )
        self.send( data )

        # send an ok
        self.send( struct.pack( '>hh', Packet.shortLength, Packet.OK ) )

        return Packet.shortLength


    def handleJoinPacket (self, data):
        # do we already have a game?
        if self.game is not None:
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return Packet.shortLength

        (gameId, ) = struct.unpack_from( '>h', data, 0 )

        # find a game
        self.game = self.gameManager.getGame( gameId )

        if self.game is None:
            self.logger.warning('handleJoinPacket: no game found with id: %d', gameId )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
        else:
            self.logger.debug('handleJoinPacket: joining game: %s', self.game )

            # sanity check
            if self.game.player2 is not None:
                self.logger.warning( 'handleJoinPacket: game %s is already full, can not join' % self.game)
                self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            else:
                self.game.player2 = self

                # activate the game
                self.gameManager.activateGame( self.game )

                self.logger.debug( 'handleJoinPacket: joined game %s', self.game )

                # send to both players a "game starts" packet with their own tokens
                data = struct.pack( '>hhhhh', struct.calcsize( '>hhhh' ), Packet.STARTS, self.game.udpPort, self.game.gameId, 0 )
                self.game.player1.send( data )
                data = struct.pack( '>hhhhh', struct.calcsize( '>hhhh' ), Packet.STARTS, self.game.udpPort, self.game.gameId, 1 )
                self.game.player2.send( data )

        return Packet.shortLength


    def handleLeavePacket (self, data):
        # do we already have a game?
        if self.game is None:
            self.logger.warning('handleLeavePacket: no current game, can not leave' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return Packet.shortLength

        (gameId, ) = struct.unpack_from( '>h', data, 0 )

        if self.game.gameId != gameId:
            self.logger.warning('handleLeavePacket: current game %s does not match: %d', self.game, gameId )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return Packet.shortLength

        self.logger.debug('handleLeavePacket: leaving game: %s', self.game )

        if self.game.removePlayer( self ) == 0:
            # the game is now empty
            self.logger.debug('handleLeavePacket: game: %s is now empty, removing', self.game )
            self.gameManager.removeGame( self.game )
        else:
            data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.ENDS, self.game.gameId )

            self.logger.debug('handleLeavePacket: ending game: %s for opponents', self.game )

            if self.game.player1 is not None and self.game.player1 != self:
                # player 1 is the connected opponent
                self.game.player1.send( data )
                self.game.player1.game = None

            elif self.game.player2 is not None and self.game.player2 != self:
                # player 2 is the connected opponent
                self.game.player2.send( data )
                self.game.player2.game = None

        # send response
        self.send( struct.pack( '>hh', Packet.shortLength, Packet.OK ) )

        # no more game
        self.game.cleanup()
        self.game = None

        return Packet.shortLength


    def handleGetGamesPacket (self, data):
        announcedGames = self.gameManager.getAnnouncedGames()

        # calculate the length of the announcing player for all games
        nameLengths = 0
        for game in announcedGames:
            nameLengths += len( game.player1.clientName )

        # total size of the games data: type, count, (game id, scenario id, name length, name) * N
        packetLength = Packet.shortLength + Packet.shortLength + len(announcedGames) * struct.calcsize( '>hhh' ) + nameLengths

        # send the first part of the data
        data = struct.pack( '>hhh', packetLength, Packet.GAME, len(announcedGames) )
        self.send( data )

        # now send the game specific data for each game
        for game in announcedGames:
            announcerName = game.player1.clientName
            nameLength = len(announcerName)
            data = struct.pack( '>hhh%ds' % nameLength, game.gameId, game.scenarioId, nameLength, announcerName )
            self.send( data )

        self.logger.debug( 'handleGetGamesPacket: sent data for %d games', len( announcedGames ) )
        return 0


    def handleGetPlayersPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.PLAYER_COUNT, self.playerManager.getPlayerCount() ) )

        for player in self.playerManager.getPlayers():
            name = player.clientName
            nameLength =  len( name )
            packetLength = struct.calcsize( '>hIh' ) + nameLength
            data = struct.pack( '>hhIh%ds' % nameLength, packetLength, Packet.PLAYER, player.clientVersion, nameLength, name )
            self.send( data )

        self.logger.debug( 'handleGetPlayersPacket: sent data for %d players', self.playerManager.getPlayerCount() )
        return 0


    def handlePingPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hh', Packet.shortLength, Packet.PONG ) )
        self.logger.debug( 'handlePingPacket: sent pong' )
        return 0


    def handleDataPacket (self, data):
        # do we already have a game?
        if self.game is None or not self.game.active:
            self.logger.warning('handleLeavePacket: no current active game' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return Packet.shortLength

        # the length of the data includes the data length 'h'
        dataLength = len( data ) - Packet.shortLength
        packetLength = struct.calcsize( '>hh' ) + dataLength

        # the data to send
        newData = struct.pack( '>hhh%ds' % dataLength, packetLength, Packet.DATA, dataLength, data )

        if self != self.game.player1:
            self.logger.debug( 'handleDataPacket: sending %d bytes of data to player 1', dataLength )
            self.game.player1.send( newData )
        else:
            self.logger.debug( 'handleDataPacket: sending %d bytes of data to player 2', dataLength )
            self.game.player2.send( newData )

        return Packet.shortLength + dataLength

