#! /usr/bin/env python

import sys
import logging
import sys
import socket
import struct
import packet
import time

from player import Player

players = []
games = []

class PacketException (Exception):
    pass


def getInputInteger (prompt, min, max):
    while True:
        try:
            value = int( raw_input(prompt) )
            if value < min or value > max:
                raise ValueError()

            return value

        except ValueError:
            print "Invalid value, valid: [%d..%d]" % (min, max)
        continue


def readPacket (sock, packetType):
    # raw data
    data = packet.Packet.readRawPacket( sock )
    if not data:
        print 'failed to read packet'
        raise PacketException()

    # extract the packet type
    (receivedType, ) = struct.unpack_from( '>h', data, 0 )

    if receivedType != packetType:
        print 'unexpected packet, got %s, expected %s' % (packet.Packet.name( receivedType ), packet.Packet.name( packetType ) )
        raise PacketException()

    # strip off the type
    return data[ packet.Packet.shortLength: ] 


def readStatusPacket (sock):
    # raw data
    data = packet.Packet.readRawPacket( sock )
    if not data:
        print 'failed to read status packet'
        raise PacketException()

    # extract the packet type
    (receivedType, ) = struct.unpack_from( '>h', data, 0 )

    if receivedType != packet.Packet.OK and receivedType != packet.Packet.ERROR:
        print 'unexpected packet, got %s, expected OK or ERROR' % (packet.Packet.name( receivedType ), packet.Packet.name( packetType ) )
        raise PacketException()

    return receivedType


def announceGame (sock):
    print ''
    print 'Announce a new game'
    scenarioId = getInputInteger( 'Scenario id: ', 0, 1000 )

    # send the request
    sock.send( packet.AnnounceGamePacket( scenarioId ).message )

    # read the announced game data
    data = readPacket( sock, packet.Packet.GAME )
    (gameId, scenarioId, playerId) = struct.unpack( '>hhh', data )

    print 'Game %d with scenario %d announced ok' % (gameId, scenarioId)


def joinGame (sock):
    print ''
    print 'Join a game'
    gameId = getInputInteger( 'Game id: ', 0, 1000 )

    # send the request
    sock.send( packet.JoinGamePacket( gameId ).message )

    # read status
    status = readStatusPacket( sock )
    if status == packet.Packet.OK:
        print 'Game %d joined ok' % gameId
    else:
        print 'Failed to join game %d' % gameId


def leaveGame (sock):
    print ''
    print 'Leave a new game we are in or hosting'
    gameId = getInputInteger( 'Game id: ', 0, 1000 )

    # send the request
    sock.send( packet.LeaveGamePacket( gameId ).message )

    # read status
    status = readStatusPacket( sock )
    if status == packet.Packet.OK:
        print 'Game left ok'
    else:
        print 'Failed to leave game'


def getPlayers (sock):
    # send the request
    sock.send( packet.GetPlayersPacket().message )

    # raw data
    data = readPacket( sock, packet.Packet.PLAYER_COUNT )
 
    (playerCount, ) = struct.unpack( '>h', data )
    #print 'players: %d' % playerCount

    # clear the list
    players = []

    # get rid of the first packet
    #response = response[ packet.Packet.headerLength + struct.calcsize( '>h' ): ]

    for index in range( playerCount ):
        # raw data
        data = readPacket( sock, packet.Packet.PLAYER )
    
        (playerId, playerVersion, nameLength) = struct.unpack_from( '>hIh', data, 0 )
        (playerName, ) = struct.unpack_from( '%ds' % nameLength, data, struct.calcsize( '>hIh' ) )

        #print 'player %d id: %d, version: %d, name: %s' % (index, playerId, playerVersion, playerName)
        players.append ( Player( playerId, playerName, playerVersion ))

    print "Received %d players:" % len(players)
    for player in players:
        print '\t', player


def getGames (sock):
    """ """
    # send the request
    sock.send( packet.GetGamesPacket().message )

    # raw data
    data = readPacket( sock, packet.Packet.GAME_COUNT )
    (gameCount, ) = struct.unpack( '>h', data, )

    games = []

    for index in range( gameCount ):
        # raw data
        data = readPacket( sock, packet.Packet.GAME )
        (gameId, scenarioId, playerId) = struct.unpack( '>hhh', data )

        #print 'player %d id: %d, version: %d, name: %s' % (index, playerId, playerVersion, playerName)
        games.append ( ( gameId, scenarioId, playerId ))

    print "Received %d games:" % len(games)
    for game in games:
        print '\tGame %d, scenario: %d, hosted by: %d' % game


def pingServer (sock):
    print ''
    print 'Pinging server 5 times'

    for i in range( 5 ):
        startTime = time.time()

        # send ping
        sock.send( packet.PingPacket().message )
        
        # read pong
        readPacket( sock, packet.Packet.PONG )

        elapsedTime = time.time() - startTime
        print "Received pong in %f ms" % (elapsedTime * 1000)


def getInput (sock):
    # loop and read input
    while True:
        print ''
        print '1: host a new game'
        print '2: join a game'
        print '3: leave a game'
        print '4: list games'
        print '5: list players'
        print '6: ping server'

        choice = getInputInteger( '> ', 1, 6 )

        # call the suitable handler
        ( announceGame, joinGame, leaveGame, getGames, getPlayers, pingServer)[ choice - 1 ]( sock )


if __name__ == '__main__':
    ip = sys.argv[1]
    port = int(sys.argv[2] )
    print 'Connecting to server on %s:%d' % (ip, port)

    # Connect to the server
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((ip, port))

    # send info
    s.send( packet.InfoPacket( "Admin", 1, 42 ).message )

    # get players
    getPlayers( s )

    # get games
    getGames( s )

    try:
        getInput( s )
    except (KeyboardInterrupt, EOFError):
        pass

    # announce our game
    # message = struct.pack( 'hhh', headerLength + struct.calcsize( 'h' ), Packet.ANNOUNCE, 202 )
    # logger.debug('sending %d bytes' % len(message) )
    # len_sent = s.send(message)

    # # get all games
    # message = struct.pack( 'hh', headerLength, Packet.GET_GAMES )
    # logger.debug('sending %d bytes' % len(message) )
    # len_sent = s.send(message)

    # # join game 0
    # message = struct.pack( 'hhh', headerLength, Packet.JOIN, 2 )
    # logger.debug('sending %d bytes' % len(message) )
    # len_sent = s.send(message)

        # Receive a response
        # logger.debug('waiting for response')
        # response = s.recv(len_sent)
        # (v1, v2) = struct.unpack( 'hh', response )
        # logger.debug('response from server: "%d %d"', v1, v2)

    # Clean up
    #print 'closing socket'
    s.close()
