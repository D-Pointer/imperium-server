#! /usr/bin/env python

import sys
import socket
import struct
import packet
import time
import string
import thread

#players = []
#games = []

# keeps the main loop running
#keepRunning = True

#gameId = None
#playerId = None

udpSocket = None
udpAddress = None


class PacketException(Exception):
    pass


def getInputInteger(prompt, min, max):
    while True:
        try:
            value = int(raw_input(prompt))
            if value < min or value > max:
                raise ValueError()

            return value

        except ValueError:
            print "Invalid value, valid: [%d..%d]" % (min, max)
        continue


def readPacket(sock, packetType):
    # raw data
    receivedType, data = packet.Packet.readRawPacket(sock)
    if not data:
        print 'failed to read packet'
        raise PacketException()

    if receivedType != packetType:
        print 'unexpected packet, got %s, expected %s' % (packet.name(receivedType), packet.name(packetType))
        raise PacketException()

    return data


def handleLoginOk():
    print "### login ok"


def handleLoginError(reason):
    print "### error logging in: %s" % reason
    sys.exit(1)


def handleAnnounceOk(data):
    (gameId,) = struct.unpack('>I', data)
    print "### announced ok, game id: %d" % gameId


def handleAlreadyAnnounced():
    print "### already announced a game, can not announce new"


def handleGameAdded(data):
    (gameId, scenarioid, nameLength) = struct.unpack_from('>Ihh', data, 0)
    (playerName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>Ihh'))
    print "### game added by %s, id: %d, scenario: %d" % (playerName, gameId, scenarioid)


def handleGameRemoved(data):
    (gameId, ) = struct.unpack('>I', data)
    print "### game %d removed" % gameId


def handleNoGame():
    print "### no game, can not leave"


def readNextPacket(sock):
    while True:
        receivedType, data = packet.Packet.readRawPacket(sock)

        if receivedType == packet.Packet.LOGIN_OK:
            handleLoginOk()

        elif receivedType == packet.Packet.INVALID_NAME:
            handleLoginError("invalid name")
        elif receivedType == packet.Packet.SERVER_FULL:
            handleLoginError("server full")
        elif receivedType == packet.Packet.NAME_TAKEN:
            handleLoginError("name taken")

        elif receivedType == packet.Packet.ANNOUNCE_OK:
            handleAnnounceOk(data)

        elif receivedType == packet.Packet.ALREADY_ANNOUNCED:
            handleAlreadyAnnounced()

        elif receivedType == packet.Packet.GAME_ADDED:
            handleGameAdded(data)

        elif receivedType == packet.Packet.GAME_REMOVED:
            handleGameRemoved(data)

        elif receivedType == packet.Packet.NO_GAME:
            handleGameRemoved(data)


def readOneOfPacket(sock, packetTypes):
    # raw data
    data = packet.Packet.readRawPacket(sock)
    if not data:
        print 'failed to read packet'
        raise PacketException()

    # extract the packet type
    (receivedType,) = struct.unpack_from('>h', data, 0)

    if receivedType not in packetTypes:
        print 'unexpected packet, got %s, expected one of %s' % (
            packet.name(receivedType), string.join(map(packet.name, packetTypes)))
        raise PacketException()

    # strip off the type
    return receivedType, data[packet.Packet.shortLength:]


def readStatusPacket(sock):
    # raw data
    data = packet.Packet.readRawPacket(sock)
    if not data:
        print 'failed to read status packet'
        raise PacketException()

    # extract the packet type
    (receivedType,) = struct.unpack_from('>h', data, 0)

    if receivedType != packet.Packet.OK and receivedType != packet.Packet.ERROR:
        print 'unexpected packet, got %s, expected OK or ERROR' % packet.name(receivedType)
        raise PacketException()

    # ok/error, so get the tag too
    (tag,) = struct.unpack_from('>h', data, packet.Packet.shortLength)

    return (tag, receivedType)


def announceGame(sock):
    print ''
    print 'Announce a new game'
    scenarioId = getInputInteger('Scenario id: ', 0, 1000)

    # send the request
    sock.send(packet.AnnounceGamePacket(scenarioId).message)

    # readNextPacket( sock )

    # read status
    # readTag, status = readStatusPacket(sock)
    # if status == packet.Packet.OK and tag == readTag:
    #     print 'Game announced ok'
    #
    #     # read the announced game data
    #     try:
    #         data = readPacket(sock, packet.Packet.GAME_ADDED)
    #         (gameId, scenarioId, nameLength) = struct.unpack_from('>hhh', data, 0)
    #         (playerName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>hhh'))
    #
    #         print 'Game %d, tag: %d, scenario: %d, announcer: %s' % (gameId, tag, scenarioId, playerName)
    #
    #     except PacketException:
    #         print 'Failed to read announced game data'
    # else:
    #     print 'Failed to announce game'


def waitForStart(sock):
    print ''
    print 'Waiting for game to start...'

    # read the start packet
    try:
        global udpSocket, udpAddress, gameId, playerId

        data = readPacket(sock, packet.Packet.STARTS)
        (udpPort, gameId, playerId, nameLength) = struct.unpack_from('>hhhh', data, 0)
        (opponentName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>hhhh'))
        print 'Game %d started ok, we are: %d, opponent is: %s, data on UDP port: %d' % (
            gameId, playerId, opponentName, udpPort)

        # create the UDP socket
        udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udpAddress = (sock.getpeername()[0], udpPort)
        # udpSocket.connect( udpAddress )
        udpSocket.bind(('', 0))

    except PacketException:
        print 'Game failed to start'


def joinGame(sock):
    global udpSocket, udpAddress, gameId, playerId

    print ''
    print 'Join a game'
    gameId = getInputInteger('Game id: ', 0, 1000)

    # send the request
    sock.send(packet.JoinGamePacket(gameId).message)

    # read the start packet
    try:
        data = readPacket(sock, packet.Packet.STARTS)
        (udpPort, gameId, playerId, nameLength) = struct.unpack_from('>hhhh', data, 0)
        (opponentName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>hhhh'))
        print 'Game %d joined ok, we are: %d, opponent is: %s, data on UDP port: %d' % (
            gameId, playerId, opponentName, udpPort)

        # create the UDP socket
        udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        udpAddress = (sock.getpeername()[0], udpPort)
        # udpSocket.connect( udpAddress )
        udpSocket.bind(('', 0))

    except PacketException:
        print 'Failed to join game %d' % gameId


def leaveGame(sock):
    # print ''
    # print 'Leave a new game we are in or hosting'
    # gameId = getInputInteger('Game id: ', 0, 1000)

    print 'Leaving game'

    # send the request
    sock.send(packet.LeaveGamePacket().message)

    # read status
    # tag, status = readStatusPacket(sock)
    # if status == packet.Packet.OK:
    #     print 'Game left ok'
    #
    #     # read the left game data
    #     try:
    #         data = readPacket(sock, packet.Packet.GAME_REMOVED)
    #         (gameId,) = struct.unpack('>h', data)
    #
    #         print 'Game %d left' % gameId
    #
    #     except PacketException:
    #         print 'Failed to read announced game data'
    # else:
    #     print 'Failed to leave game'


# def getPlayerCount(sock):
#     # send the request
#     sock.send(packet.GetPlayerCountPacket().message)
#
#     # raw data
#     data = readPacket(sock, packet.Packet.PLAYER_COUNT)
#
#     (playerCount,) = struct.unpack('>h', data)
#     print 'Connected players: %d' % playerCount
#
#     # clear the list
#     # players = []
#
#     # get rid of the first packet
#     # response = response[ packet.Packet.headerLength + struct.calcsize( '>h' ): ]
#
#     # for index in range(playerCount):
#     #    # raw data
#     #    data = readPacket(sock, packet.Packet.PLAYER)
#
#     #    (playerVersion, nameLength) = struct.unpack_from('>h', data, 0)
#     #    (playerName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>Ih'))
#     #    players.append(Player( playerName, playerVersion ))
#
#     # print "Received %d players:" % len(players)
#     # for player in players:
#     #    print '\t', player


# def getGames(sock):
#     """ """
#     # send the request
#     sock.send(packet.GetGamesPacket().message)
#
#     games = []
#
#     # read the games packet
#     data = readPacket(sock, packet.Packet.GAMES)
#     (count,) = struct.unpack_from('>h', data, 0)
#
#     # start past the game count
#     offset = packet.Packet.shortLength;
#
#     for index in range(count):
#         (gameId, scenarioId, nameLength) = struct.unpack_from('>hhh', data, offset)
#         offset += struct.calcsize('>hhh')
#
#         # get the announcing player name
#         (playerName,) = struct.unpack_from('%ds' % nameLength, data, offset)
#         offset += nameLength
#
#         # save for later
#         games.append((gameId, scenarioId, playerName))
#
#     print "Received %d games:" % len(games)
#     for game in games:
#         print '\tGame %d, scenario: %d, hosted by: %s' % game


def pingServer(sock):
    print ''
    print 'Pinging server 5 times'

    for i in range(5):
        startTime = time.time()

        # send ping
        sock.send(packet.PingPacket().message)

        # read pong
        readPacket(sock, packet.Packet.PONG)

        elapsedTime = time.time() - startTime
        print "Received pong in %f ms" % (elapsedTime * 1000)


def sendTcpDataPacket(sock):
    data = raw_input('Data to send: ')

    if data is None:
        return

    # send data
    sock.send(packet.DataPacket(data).message)


def sendUdpDataPacket(sock):
    data = raw_input('Data to send: ')

    if data is None:
        return

    global udpAddress

    # send data
    udpSocket.sendto(data, udpAddress)
    # udpSocket.sendto( packet.UdpDataPacket( playerId, gameId, data ).message, udpAddress )


def readUdpPacket(sock):
    global udpSocket  # , gameId

    # read raw data from the UDP socket
    data, sender = udpSocket.recvfrom(512)
    if not data:
        print 'failed to read UDP packet'
        raise PacketException()

    # extract the header
    # (length, senderId, tmpGameId, ) = struct.unpack_from('>hhh', data, 0)

    # extra the payload
    # headerLength = struct.calcsize( '>hhh' )
    # content = data[ headerLength : headerLength + length ]

    print ''
    print 'read UDP packet from %s, bytes: %d, data: "%s"' % (sender, len(data), data)
    # print 'read UDP packet from %d, game: %d, bytes: %d, data: "%s"' % ( senderId, tmpGameId, len(content), content )


# def register(sock, name, secret):
#     tag = 0
#     sock.send(packet.RegisterPacket(tag, name, secret).message)
#
#     # read the response
#     packetType, data = readOneOfPacket(sock, (packet.Packet.REGISTER_OK, packet.Packet.ERROR))
#
#     if packetType == packet.Packet.ERROR:
#         print "Failed to register"
#         return
#
#     # ok/error, so get the tag too
#     (tag, id) = struct.unpack('>hI', data)
#     print 'Registered ok, id: %d' % id


def login(sock, name):
    sock.send(packet.LoginPacket(name).message)
    # if not readNextPacket( sock ):
    #    return False

    # return True


# def subscribe(sock):
#     tag = 0
#     sock.send(packet.SubscribePacket(tag).message)
#
#     # read status
#     readTag, status = readStatusPacket(sock)
#     if status == packet.Packet.OK and tag == readTag:
#         print 'Subscribed ok to game status updates'
#     else:
#         print 'Failed to subscribed to game status updates'
#
#
# def unsubscribe(sock):
#     sock.send(packet.UnsubscribePacket().message)
#
#     # read status
#     status = readStatusPacket(sock)
#     if status == packet.Packet.OK:
#         print 'Unsubscribed ok from game status updates'
#     else:
#         print 'Failed to unsubscribed from game status updates'


def quit(sock):
    print 'quitting'
    sys.exit( 0 )

def getInput(sock):
    # loop and read input
    while True:
        print ''
        print '0: quit'
        print '1: announce a new game'
        print '2: leave a game'
        # print '2: join a game'
        # print '4: list games'
        # print '5: get player count'
        # print '6: ping server'
        # print '8: wait for game to start'
        # print '9: send TCP data'
        # print '10: send UDP data'
        # print '11: read UDP data'
        # print '12: subscribe to game status updates'
        # print '13: unsubscribe from game status updates'

        callbacks = (quit, announceGame, leaveGame )
        choice = getInputInteger('> ', 0, len(callbacks))

        # call the suitable handler
        callbacks[choice](sock)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print "Usage: %s server port name" % sys.argv[0]
        exit(1)

    server = sys.argv[1]
    port = int(sys.argv[2])
    name = sys.argv[3]

    print 'Connecting to server on %s:%d' % (server, port)

    # Connect to the server
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((server, port))
    except:
        print 'Error connecting to the server, aborting'
        sys.exit(1)

    # log in
    login(s, name)

    # set up a thread to read packets
    thread.start_new_thread(readNextPacket, (s,))

    # we want update
    # subscribe(s)

    # get players
    # getPlayerCount(s)

    # get games
    # getGames(s)

    try:
        getInput(s)
    except (KeyboardInterrupt, EOFError):
        pass

    s.close()
