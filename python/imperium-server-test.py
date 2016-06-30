#! /usr/bin/env python

import sys
import socket
import struct
import datetime
import thread
import ssl

import packet
from unit import Unit
from simulator import Simulator

server = None
port = -1
playerId = -1

# player army
units = []

simulator = None

udpSocket = None
udpAddress = None

PROTOCOL_VERSION = 0

UDP_TYPE_TEXT = 0
UDP_TYPE_TEST = 1

udpSpeedTestStart = None



def readUdpPackets(udpSocket):
    print "--- reading UDP packets"
    while True:
        data, addr = udpSocket.recvfrom(2048)
        print "--- read %d bytes from %s:%d" % (len(data), addr[0], addr[1])

        (packetType,) = struct.unpack_from('>B', data, 0)

        if packetType == packet.Packet.UDP_PONG:
            (oldTime,) = struct.unpack_from('>L', data, struct.calcsize('>B'))
            now = datetime.datetime.now()
            milliseconds = (now.day * 24 * 60 * 60 + now.second) * 1000 + now.microsecond / 1000
            print "--- pong received, time: %d ms" % (milliseconds - oldTime)

        elif packetType == packet.Packet.UDP_DATA_START_ACTION:
            print "--- start action, starting simulator"
            # create the simulator and start it
            simulator = Simulator( units, udpSocket, udpAddress )
            simulator.start()

        elif packetType == packet.Packet.UDP_DATA:
            (packetType, subPacketType, packetId,) = struct.unpack_from('>BBL', data, 0)
            offset = struct.calcsize('>BBL')
            print "--- UDP data type %d, packet id: %d, total bytes: %d" % (subPacketType, packetId, len(data))

            if subPacketType == packet.Packet.UDP_DATA_MISSION:
                (unitCount,) = struct.unpack_from('>B', data, offset)
                offset += struct.calcsize('>B')
                print "--- mission data, %d units" % unitCount

                for count in range( unitCount ):
                    (unitId, missionType, ) = struct.unpack_from('>hB', data, offset)
                    offset += struct.calcsize('>hB')
                    print "--- unit %d, mission %d" % (unitId, missionType )

            elif subPacketType == packet.Packet.UDP_DATA_UNIT_STATS:
                (unitCount,) = struct.unpack_from('>B', data, offset)
                offset += struct.calcsize('>B')
                print "--- unit stats, %d units" % unitCount

                for count in range( unitCount ):
                    (unitId, men, mode, missionType, morale, fatigue, ammo, x, y, facing, ) = struct.unpack_from('>hBBBBBBhhh', data, offset)
                    offset += struct.calcsize('>hBBBBBBhhh')

                    # convert some data back
                    x /= 10
                    y /= 10
                    facing /= 10

                    print "--- unit %d, men: %d, mode: %d, mission %d, morale: %d, fatigue: %d, ammo: %d pos: %d,%d, facing: %d" \
                          % (unitId, men, mode, missionType, morale, fatigue, ammo, x, y, facing)

            elif subPacketType == packet.Packet.UDP_DATA_FIRE:
                (attackerId, x, y, targetCount, ) = struct.unpack_from('>hhhB', data, offset)
                offset += struct.calcsize('>hhhB')
                x /= 10
                y /= 10
                print "--- fire, %d fires at %d,%d, hitting %d units" % (attackerId, x, y, targetCount )

                for count in range( unitCount ):
                    (targetId, casualties, type, targetMoraleChange, attackerMoraleChange, ) = struct.unpack_from('>hBBhh', data, offset)
                    offset += struct.calcsize('>hBBhh')
                    targetMoraleChange /= 10.0
                    attackerMoraleChange /= 10.0
                    print "    target %d lost %d men, type: %d, attacker morale: %.1f, target morale: %.1f" % (targetId, casualties, type, attackerMoraleChange, targetMoraleChange)


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
    (gameId,) = struct.unpack('>I', data)
    print "### game %d removed" % gameId


def handleNoGame():
    print "### no game, can not leave"


def handleGameJoined(data):
    (udpPort, nameLength,) = struct.unpack_from('>hh', data, 0)
    (opponentName,) = struct.unpack_from('%ds' % nameLength, data, struct.calcsize('>hh'))
    print "### game joined, UDP port: %d, opponent: %s" % (udpPort, opponentName)
    print "### starting UDP thread"

    global udpAddress, udpSocket
    udpAddress = (server, udpPort)
    udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    thread.start_new_thread(readUdpPackets, (udpSocket,))

    # send an initial "ping" to open up the connection so that the server knows our port
    print "### sending UDP ping"
    udpSocket.sendto(packet.UdpPingPacket().message, udpAddress)

    # set up our army
    global units
    units = []
    for baseId in range( 10 ):
        units.append( Unit( playerId, baseId ))
    print "created %d units" % len( units )


def handleGameJoinError(reason):
    print "### error joining game: %s" % reason


def handleGameEnded():
    print "### game has ended"


def handleData(data, sock):
    print "### received TCP data, %d bytes" % len(data)
    offset = 0
    (subPacketType, ) = struct.unpack_from('>B', data, 0)
    offset += struct.calcsize('>B')

    if subPacketType == packet.Packet.SETUP_UNITS:
        (unitCount, ) = struct.unpack_from('>B', data, offset)
        offset += struct.calcsize('>B')
        print "### setup data for %d units" % unitCount

        # read data for all units
        for count in range( unitCount ):
            (unitId, x, y, rotation, type, men, mode, mission, morale, fatigue, experience, ammo, weapon, nameLength) = struct.unpack_from('>hhhhBBBBBBBBBB', data, offset)
            offset += struct.calcsize('>hhhhBBBBBBBBBB')
            (unitName,) = struct.unpack_from('%ds' % nameLength, data, offset)
            offset += nameLength
            print "### unit %d, %s pos: %d,%d, facing: %d, men: %d" % (unitId, unitName, x / 10, y / 10, rotation / 10, men)
            print "###     mode: %d, mission: %d, mor/fat/exp: %d/%d/%d, weapon/ammo: %d/%d" % (mode, mission, morale, fatigue, experience, weapon, ammo)

        # send back our units and ready to start packet
        print "### sending own units packet"
        sock.send(packet.SendUnitsPacket( units ).message)

        print "### sending ready to start packet"
        sock.send(packet.ReadyToStartPacket().message)

    else:
        print "### unknown TCP sub packet type: %d" % subPacketType


def handleResource(data):
    (dataLength,) = struct.unpack_from('>h', data, 0)
    (data,) = struct.unpack_from('%ds' % dataLength, data, struct.calcsize('>h'))
    print "### resoure data:\n%s\n" % data


def handleInvalidResource(data):
     print "### invalid resource"


def readNextPacket(sock):
    # try:
    while True:
        receivedType, data = packet.Packet.readRawPacket(sock)

        if receivedType == packet.Packet.LOGIN_OK:
            handleLoginOk()

        elif receivedType == packet.Packet.INVALID_NAME:
            handleLoginError("invalid name")
        elif receivedType == packet.Packet.ALREADY_LOGGED_IN:
            handleLoginError("already logged in")
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
            handleNoGame()

        # game join results
        elif receivedType == packet.Packet.GAME_JOINED:
            handleGameJoined(data)
        elif receivedType == packet.Packet.INVALID_GAME:
            handleGameJoinError("invalid game")
        elif receivedType == packet.Packet.ALREADY_HAS_GAME:
            handleGameJoinError("we already have a game")
        elif receivedType == packet.Packet.GAME_FULL:
            handleGameJoinError("game full")

        elif receivedType == packet.Packet.GAME_ENDED:
            handleGameEnded()

        elif receivedType == packet.Packet.DATA:
            handleData(data, sock)

        elif receivedType == packet.Packet.RESOURCE_PACKET:
            handleResource(data)

        elif receivedType == packet.Packet.INVALID_RESOURCE_PACKET:
            handleInvalidResource(data)

        else:
            print "### unknown packet type: %d" % receivedType
            # except Exception,e:
            #    print "Caught exception:"
            #    print str(e)
            #  sys.exit( 1 )


def announceGame(sock):
    print ''
    print 'Announce a new game'
    scenarioId = getInputInteger('Scenario id: ', 0, 1000)

    # send the request
    sock.send(packet.AnnounceGamePacket(scenarioId).message)

    # we're player 1
    playerId = 0


def joinGame(sock):
    gameId = getInputInteger('Game to join id: ', 0, 1000)

    # send the request
    sock.send(packet.JoinGamePacket(gameId).message)

    # we're player 2
    playerId = 2


def leaveGame(sock):
    print 'Leaving game'

    # send the request
    sock.send(packet.LeaveGamePacket().message)


# def readyToStart(sock):
#     print 'Sending ready to start game'
#
#     # send the request
#     sock.send(packet.ReadyToStartPacket().message)


def pingServer(sock):
    print ''
    print 'Sending ping'
    udpSocket.sendto(packet.UdpPingPacket().message, udpAddress)


def sendTcpDataPacket(sock):
    data = raw_input('TCP data to send: ')

    if data is None:
        return

    # send data
    sock.send(packet.DataPacket(data).message)


def sendUdpDataPacket(sock):
    data = raw_input('UDP data to send: ')

    if data is None:
        return

    global udpAddress

    # send data
    udpSocket.sendto(packet.UdpDataPacket(packet.Packet.UDP_DATA_MISSION, data).message, udpAddress)


def sendUdpTestData(sock):
    startValue = 0

    global udpAddress, udpSpeedTestStart

    now = datetime.datetime.now()
    udpSpeedTestStart = (now.day * 24 * 60 * 60 + now.second) * 1000 + now.microsecond / 1000

    # send data
    udpSocket.sendto(packet.UdpDataPacket(UDP_TYPE_TEST, startValue).message, udpAddress)


def getResource(sock):
    data = raw_input('Name of resource: ')

    if data is None:
        return

    # send data
    sock.send(packet.GetResourcePacket(data).message)


def login(sock, name):
    sock.send(packet.LoginPacket(PROTOCOL_VERSION, name).message)


def quit(sock):
    print 'quitting'
    sys.exit(0)


def getInput(sock):
    # loop and read input
    while True:
        print ''
        print '0: quit'
        print '1: announce a new game'
        print '2: join a game'
        print '3: leave a game'
        #print '4: ready to start'
        print '4: ping'
        print '5: send TCP data'
        print '6: send UDP data'
        print '7: send UDP game data'
        print '8: get resource'
        # print '2: join a game'
        # print '4: list games'

        callbacks = (
        quit, announceGame, joinGame, leaveGame, pingServer, sendTcpDataPacket, sendUdpDataPacket, sendUdpTestData, getResource)
        choice = getInputInteger('> ', 0, len(callbacks))

        # call the suitable handler
        callbacks[choice](sock)


if __name__ == '__main__':
    if len(sys.argv) != 4 and len(sys.argv) != 5:
        print "Usage: %s server port name [ssl]" % sys.argv[0]
        exit(1)

    server = sys.argv[1]
    port = int(sys.argv[2])
    name = sys.argv[3]

    if len(sys.argv) == 5:
        useSsl = True
    else:
        useSsl = False

    print 'Connecting to server on %s:%d' % (server, port)

    # Connect to the server
    try:
        s = None
        if useSsl:
            context = ssl.create_default_context()
            s = context.wrap_socket(socket.socket(socket.AF_INET, socket.SOCK_STREAM), server_hostname=server)
        else:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((server, port))
    except:
        print 'Error connecting to the server, aborting'
        raise
        sys.exit(1)

    # log in
    login(s, name)

    # set up a thread to read packets
    thread.start_new_thread(readNextPacket, (s,))

    try:
        getInput(s)
    except (KeyboardInterrupt, EOFError):
        pass

    s.close()
