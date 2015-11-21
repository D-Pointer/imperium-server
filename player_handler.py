import asyncore
import socket
import struct

import player
from packet         import Packet, name, OkPacket, ErrorPacket, RegisterOkPacket

class PlayerHandler(asyncore.dispatcher_with_send):

    handlerId = 0

    def __init__ (self, sock, logger, playerManager, gameManager, registrationManager):
        asyncore.dispatcher_with_send.__init__(self, sock)
        self.logger = logger
        PlayerHandler.handlerId += 1

        # no player data yet
        self.player = None
        self.data = ''

        # registration handling
        self.registrationManager = registrationManager

        # all connected players
        self.playerManager = playerManager

        # all active games
        self.gameManager = gameManager

        # our game that we're announcing or in
        self.game = None

        # are we subscribed to game status updated?
        self.subscribed = False


    def handle_read(self):
        try:
            data = self.recv(8192)
        except socket.error:
            self.logger.debug('failed to receive data')
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
                self.logger.debug('can not read full header' )
                return

            # get the packet length
            (packetLength, packetType) = Packet.parseHeader( self.data )
            self.logger.info('packet: %s, size: %d', name( packetType ), packetLength )

            # can we read the rest of the packet?
            if len(self.data) < packetLength:
                self.logger.warning('can not read full packet' )
                return

            # handle the packet
            self.handlePacket( packetType, self.data[ Packet.headerLength:Packet.shortLength + packetLength ] )

            # strip off the handled packet
            self.data = self.data[ Packet.shortLength + packetLength: ] #Packet.headerLength + payloadLength: ]


    def handle_close(self):
        self.close()

        if self.playerManager.removePlayer( self ):
            self.logger.debug('player removed, now %d players' % self.playerManager.getPlayerCount() )
        else:
            self.logger.warning('self not found among players!')

        # do we have a game?
        if self.game is not None:
            self.logger.debug('ending game %s' % self.game )
            data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.GAME_REMOVED, self.game.gameId )

            # tell all connected players that the game has been removed
            for player in self.playerManager.getPlayers():
                if player.subscribed:
                    player.send( data )

            self.gameManager.removeGame( self.game )
            self.game.cleanup()
            self.game = None


    def handlePacket (self, packetType, data):
        if packetType == Packet.REGISTER:
            self.handleRegisterPacket( data )

        elif packetType == Packet.LOGIN:
            self.handleLoginPacket( data )

        elif packetType == Packet.ANNOUNCE:
            self.handleAnnouncePacket( data )

        elif packetType == Packet.JOIN:
            self.handleJoinPacket( data )

        elif packetType == Packet.LEAVE:
            self.handleLeavePacket( data )

        elif packetType == Packet.GET_GAMES:
            self.handleGetGamesPacket( data )

        elif packetType == Packet.GET_PLAYER_COUNT:
            self.handleGetPlayerCountPacket( data )

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
            self.logger.error( 'unknown packet type: %d', packetType )


    def handleRegisterPacket (self, data):
        ( tag, secret, nameLength) = struct.unpack_from( '>hIh', data, 0 )
        ( name, ) = struct.unpack_from( '>%ds' % nameLength, data, struct.calcsize('>hIh') )

        self.logger.debug( 'registering %s, secret %d, tag: %d', name, secret, tag )

        # already registered?
        if self.player is not None:
            self.logger.warning( 'player already logged in, can not register')
            self.send( ErrorPacket( tag ).message )
            return

        # try to register the new player
        self.player = self.registrationManager.register( name, secret )
        if self.player is None:
            self.logger.warning( 'name %s already taken, can not register', name)
            self.send( ErrorPacket( tag ).message )
            return

        self.logger.debug('player: %s, tag: %d', self.player, tag )

        # send an ok to the registering player
        self.send( RegisterOkPacket( tag, self.player.id ).message )


    def handleLoginPacket (self, data):
        ( tag, id, secret, version) = struct.unpack( '>hIII', data )
        self.logger.debug('validating client, id: %d, secret: %d, version: %d, tag: %d', id, secret, version, tag )

        self.player = self.registrationManager.getPlayer( id, secret )

        # player ok?
        if self.player is None:
            self.send( ErrorPacket( tag ).message )
            self.logger.debug('failed to log in player with id: %d', id )
        else:
            # logged in ok
            self.send( OkPacket( tag ).message )
            self.logger.debug('player logged in ok: %s', self.player )


    def handleAnnouncePacket (self, data):
        (scenarioId, tag) = struct.unpack_from( '>hh', data, 0 )

        # do we already have a game?
        if self.game is not None:
            self.logger.warning('we already have a game: %s, can not announce a new game' % self.game )
            self.send( ErrorPacket( tag ).message )
            return

        # create a new announced game
        self.game = self.gameManager.createGame( scenarioId, self )
        self.gameManager.addGame( self.game )
        self.logger.debug('announce game: %d with scenario: %d, tag: %d', self.game.gameId, self.game.scenarioId, tag )
        self.logger.debug('announced games now: %d', len( self.gameManager.getAnnouncedGames() ) )

        # send an ok to the announcing player
        self.send( OkPacket( tag ).message )

        nameLength = len( self.player.name )
        length = struct.calcsize( '>hhhh' ) + nameLength
        data = struct.pack( '>hhhhh%ds' % nameLength, length, Packet.GAME_ADDED, self.game.gameId, self.game.scenarioId, nameLength, self.player.name )

        # send the game to all connected players
        for player in self.playerManager.getPlayers():
            if player.subscribed:
                player.send( data )


    def handleJoinPacket (self, data):
        # do we already have a game?
        if self.game is not None:
            self.logger.warning('we already have a game: %s, can not join new game' % self.game )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

        (gameId, ) = struct.unpack_from( '>h', data, 0 )

        # find a game
        self.game = self.gameManager.getGame( gameId )

        if self.game is None:
            self.logger.warning('no game found with id: %d', gameId )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
            return

        self.logger.debug('joining game: %s', self.game )

        # sanity check
        if self.game.player2 is not None:
            self.logger.warning( 'game %s is already full, can not join' % self.game)
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )
        else:
            self.game.player2 = self

            # activate the game
            self.gameManager.activateGame( self.game )

            # player names
            player1Name = self.game.player1.player.name
            player2Name = self.player.name

            self.logger.debug( 'joined game %s', self.game )

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
            self.logger.warning('no current game, can not leave' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

        (tag, ) = struct.unpack_from( '>h', data, 0 )

        self.logger.debug('leaving game: %s', self.game )

        # send response
        self.send( OkPacket( tag ).message )

        # tell all connected players that the game has been removed
        data = struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.GAME_REMOVED, self.game.gameId )
        for player in self.playerManager.getPlayers():
            if player.subscribed:
                player.send( data )

        self.logger.debug('removing game: %s', self.game )

        # no more game
        self.gameManager.removeGame( self.game )
        self.game.cleanup()
        self.game = None


    def handleGetGamesPacket (self, data):
        announcedGames = self.gameManager.getAnnouncedGames()

        # calculate the length of the announcing player for all games
        nameLengths = 0
        for game in announcedGames:
            nameLengths += len( game.player1.player.name )

        # total size of the games data: type, count, (game id, scenario id, name length, name) * N
        packetLength = Packet.shortLength + Packet.shortLength + len(announcedGames) * struct.calcsize( '>hhh' ) + nameLengths

        # send the first part of the data
        data = struct.pack( '>hhh', packetLength, Packet.GAMES, len(announcedGames) )
        self.send( data )

        # now send the game specific data for each game
        for game in announcedGames:
            announcerName = game.player1.player.name
            nameLength = len(announcerName)
            data = struct.pack( '>hhh%ds' % nameLength, game.gameId, game.scenarioId, nameLength, announcerName )
            self.send( data )

        self.logger.debug( 'sent data for %d games', len( announcedGames ) )


    def handleGetPlayerCountPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.PLAYER_COUNT, self.playerManager.getPlayerCount() ) )


    def handleGetPlayersPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hhh', struct.calcsize( '>hh' ), Packet.PLAYER_COUNT, self.playerManager.getPlayerCount() ) )

        for player in self.playerManager.getPlayers():
            name = player.player.name
            nameLength =  len( name )
            packetLength = struct.calcsize( '>hh' ) + nameLength
            data = struct.pack( '>hhh%ds' % nameLength, packetLength, Packet.PLAYER, nameLength, name )
            self.send( data )

        self.logger.debug( 'sent data for %d players', self.playerManager.getPlayerCount() )


    def handlePingPacket (self, data):
        # send the player count packet
        self.send( struct.pack( '>hh', Packet.shortLength, Packet.PONG ) )
        self.logger.debug( 'sent pong' )


    def handleSubscribePacket (self, data):
        # send the player count packet
        (tag, ) = struct.unpack_from( '>h', data, 0 )
        self.logger.debug( 'subscribing to game status updates, tag: %d', tag )
        self.subscribed = True
        self.send( OkPacket( tag ).message )


    def handleUnsubscribePacket (self, data):
        # send the player count packet
        (tag, ) = struct.unpack_from( '>h', data, 0 )
        self.logger.debug( 'unsubscribing from game status updates, tag: %d', tag )
        self.subscribed = False
        self.send( OkPacket( tag ).message )


    def handleDataPacket (self, data):
        # do we already have a game?
        if self.game is None or not self.game.active:
            self.logger.warning( 'no current active game' )
            self.send( struct.pack( '>hh', Packet.shortLength, Packet.ERROR ) )

        # the length of the data includes the data length 'h'
        dataLength = len( data ) - Packet.shortLength
        packetLength = struct.calcsize( '>hh' ) + dataLength

        # the data to send
        newData = struct.pack( '>hhh%ds' % dataLength, packetLength, Packet.DATA, dataLength, data )

        if self != self.game.player1:
            self.logger.debug( 'sending %d bytes of data to player 1', dataLength )
            self.game.player1.send( newData )
        else:
            self.logger.debug( 'sending %d bytes of data to player 2', dataLength )
            self.game.player2.send( newData )

