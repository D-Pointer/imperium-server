import logging
import asyncore
import socket
import struct

from packet         import Packet, name, OkPacket, ErrorPacket

class PlayerHandler(asyncore.dispatcher_with_send):

    handlerId = 0

    def __init__ (self, sock, playerManager, gameManager):
        asyncore.dispatcher_with_send.__init__(self, sock)
        self.logger = logging.getLogger('PlayerHandler-%d' % PlayerHandler.handlerId)
        PlayerHandler.handlerId += 1

        self.clientVersion = -1
        self.clientName = 'unknown'
        self.data = ''

        self.playerManager = playerManager
        self.gameManager = gameManager

        # our game that we're announing or in
        self.game = None

        # are we subscribed to game status updated?
        self.subscribed = False


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
            self.logger.info('handle_read: packet: %s', name( packetType ) )

            # can we read the rest of the packet?
            if len(self.data) < packetLength:
                self.logger.warning('handle_read: can not read full packet' )
                return

            # handle the packet
            self.handlePacket( packetType, self.data[ Packet.headerLength:Packet.headerLength + packetLength ] )

            # strip off the handled packet
            self.data = self.data[ Packet.shortLength + packetLength: ] #Packet.headerLength + payloadLength: ]


    def handle_close(self):
        self.close()

        if self.playerManager.removePlayer( self ):
            self.logger.debug('handle_close: player removed, now %d players' % self.playerManager.getPlayerCount() )
        else:
            self.logger.warning('handle_close: self not found among players!')

        # do we have a game?
        if self.game is not None:
            self.logger.debug('handle_close: ending game %s' % self.game )
            data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.GAME_REMOVED, self.game.gameId )

            # tell all connected players that the game has been removed
            for player in self.playerManager.getPlayers():
                if player.subscribed:
                    player.send( data )

            self.gameManager.removeGame( self.game )
            self.game.cleanup()
            self.game = None


    def handlePacket (self, packetType, data):
        if packetType == Packet.INFO:
            self.handleInfoPacket( data )

        elif packetType == Packet.ANNOUNCE:
            self.handleAnnouncePacket( data )

        elif packetType == Packet.JOIN:
            self.handleJoinPacket( data )

        elif packetType == Packet.LEAVE:
            self.handleLeavePacket( data )

        elif packetType == Packet.GET_GAMES:
            self.handleGetGamesPacket( data )

        elif packetType == Packet.GET_PLAYERS:
            self.handleGetPlayersPacket( data )

        elif packetType == Packet.PING:
            self.handlePingPacket( data )

        elif packetType == Packet.SUBSCRIBE:
            self.handleSubscribePacket( data )

        elif packetType == Packet.UNSUBSCRIBE:
            self.handleUnsubscribePacket( data )

        elif packetType == Packet.DATA:
            self.handleDataPacket( data )

        else:
            self.logger.error( 'handlePacket: unknown packet type: %d', packetType )


    def handleInfoPacket (self, data):
        (tag, self.clientVersion, nameLength) = struct.unpack_from( '>hIh', data, 0 )
        (self.clientName, ) = struct.unpack_from( '>%ds' % nameLength, data, struct.calcsize('>hIh') )
        self.logger.debug('handleInfoPacket: client joined, name: %s, version: %d, tag: %d', self.clientName, self.clientVersion, tag )

        # send an ok to the announcing player
        self.send( OkPacket( tag ).message )


    def handleAnnouncePacket (self, data):
        (scenarioId, tag) = struct.unpack_from( '>hh', data, 0 )

        # do we already have a game?
        if self.game is not None:
            self.logger.warning('handleAnnouncePacket: we already have a game: %s, can not announce a new game' % self.game )
            self.send( ErrorPacket( tag ).message )
            return

        # create a new announced game
        self.game = self.gameManager.createGame( scenarioId, self )
        self.gameManager.addGame( self.game )
        self.logger.debug('handleAnnouncePacket: announce game: %d with scenario: %d, tag: %d', self.game.gameId, self.game.scenarioId, tag )
        self.logger.debug('handleAnnouncePacket: announced games now: %d', len( self.gameManager.getAnnouncedGames() ) )

        # send an ok to the announcing player
        self.send( OkPacket( tag ).message )

        nameLength = len( self.clientName )
        length = struct.calcsize( '>hhhh' ) + nameLength
        data = struct.pack( '>hhhhh%ds' % nameLength, length, Packet.GAME_ADDED, self.game.gameId, self.game.scenarioId, nameLength, self.clientName )

        # send the game to all connected players
        for player in self.playerManager.getPlayers():
            if player.subscribed:
                player.send( data )


    def handleJoinPacket (self, data):
        # do we already have a game?
        if self.game is not None:
            self.logger.warning('handleJoinPacket: we already have a game: %s, can not join new game' % self.game )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

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

                # player names
                player1Name = self.game.player1.clientName
                player2Name = self.game.player2.clientName

                self.logger.debug( 'handleJoinPacket: joined game %s', self.game )

                # send to both players a "game starts" packet with their own tokens
                dataLength = struct.calcsize( '>hhhhh' ) + len(player2Name)
                data = struct.pack( '>hhhhhh%ds' % len(player2Name), dataLength, Packet.STARTS, self.game.udpPort, self.game.gameId, 0, len(player2Name), player2Name )
                self.game.player1.send( data )

                dataLength = struct.calcsize( '>hhhhh' ) + len(player1Name)
                data = struct.pack( '>hhhhhh%ds' % len(player1Name), dataLength, Packet.STARTS, self.game.udpPort, self.game.gameId, 1, len(player1Name), player1Name )
                self.game.player2.send( data )

                # tell all other connected players that the game has been removed from them
                data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.GAME_REMOVED, self.game.gameId )
                for player in self.playerManager.getPlayers():
                    if player.subscribed and player is not self.game.player1 and player is not self.game.player2:
                        player.send( data )


    def handleLeavePacket (self, data):
        # do we already have a game?
        if self.game is None:
            self.logger.warning('handleLeavePacket: no current game, can not leave' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

        (tag, ) = struct.unpack_from( '>h', data, 0 )

        self.logger.debug('handleLeavePacket: leaving game: %s', self.game )

        # send response
        self.send( OkPacket( tag ).message )

        # tell all connected players that the game has been removed
        data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.GAME_REMOVED, self.game.gameId )
        for player in self.playerManager.getPlayers():
            if player.subscribed:
                player.send( data )

        self.logger.debug('handleLeavePacket: removing game: %s', self.game )

        # no more game
        self.gameManager.removeGame( self.game )
        self.game.cleanup()
        self.game = None


    def handleGetGamesPacket (self, data):
        announcedGames = self.gameManager.getAnnouncedGames()

        # calculate the length of the announcing player for all games
        nameLengths = 0
        for game in announcedGames:
            nameLengths += len( game.player1.clientName )

        # total size of the games data: type, count, (game id, scenario id, name length, name) * N
        packetLength = Packet.shortLength + Packet.shortLength + len(announcedGames) * struct.calcsize( '>hhh' ) + nameLengths

        # send the first part of the data
        data = struct.pack( '>hhh', packetLength, Packet.GAMES, len(announcedGames) )
        self.send( data )

        # now send the game specific data for each game
        for game in announcedGames:
            announcerName = game.player1.clientName
            nameLength = len(announcerName)
            data = struct.pack( '>hhh%ds' % nameLength, game.gameId, game.scenarioId, nameLength, announcerName )
            self.send( data )

        self.logger.debug( 'handleGetGamesPacket: sent data for %d games', len( announcedGames ) )


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


    def handlePingPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hh', Packet.shortLength, Packet.PONG ) )
        self.logger.debug( 'handlePingPacket: sent pong' )


    def handleSubscribePacket (self, data):
        # send the player count packet
        (tag, ) = struct.unpack( '>h', data )
        self.logger.debug( 'handleSubscribePacket: subscribing to game status updates, tag: %d', tag )
        self.subscribed = True
        self.send( OkPacket( tag ).message )


    def handleUnsubscribePacket (self, data):
        # send the player count packet
        (tag, ) = struct.unpack( '>h', data )
        self.logger.debug( 'handleUnsubscribePacket: unsubscribing from game status updates, tag: %d', tag )
        self.subscribed = False
        self.send( OkPacket( tag ).message )


    def handleDataPacket (self, data):
        # do we already have a game?
        if self.game is None or not self.game.active:
            self.logger.warning('handleLeavePacket: no current active game' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

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

