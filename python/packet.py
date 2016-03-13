import struct
import datetime


class Packet:
    LOGIN = 0  # to server
    LOGIN_OK = 1  # from server
    INVALID_NAME = 2
    NAME_TAKEN = 3
    SERVER_FULL = 4
    ANNOUNCE = 5  # to server
    ANNOUNCE_OK = 6
    ALREADY_ANNOUNCED = 7
    GAME_ADDED = 8
    GAME_REMOVED = 9
    LEAVE_GAME = 10
    NO_GAME = 11
    JOIN_GAME = 12
    GAME_JOINED = 13
    INVALID_GAME = 14
    ALREADY_HAS_GAME = 15
    GAME_FULL = 16
    GAME_ENDED = 17
    DATA = 18
    UDP_PING = 19
    UDP_PONG = 20

    packetNames = {
        LOGIN: 'LOGIN',
        LOGIN_OK: 'LOGIN_OK',
        INVALID_NAME: 'INVALID_NAME',
        NAME_TAKEN: 'NAME_TAKEN',
        SERVER_FULL: 'SERVER_FULL',
        ANNOUNCE: 'ANNOUNCE',
        ANNOUNCE_OK: 'ANNOUNCE_OK',
        ALREADY_ANNOUNCED: 'ALREADY_ANNOUNCED',
        GAME_ADDED: 'GAME_ADDED',
        GAME_REMOVED: 'GAME_REMOVED',
        LEAVE_GAME: 'LEAVE_GAME',
        NO_GAME: 'NO_GAME',
        JOIN_GAME: 'JOIN_GAME',
        GAME_JOINED: 'GAME_JOINED',
        INVALID_GAME: 'INVALID_GAME',
        ALREADY_HAS_GAME: 'ALREADY_HAS_GAME',
        GAME_FULL: 'GAME_FULL',
        GAME_ENDED: 'GAME_ENDED',
        DATA: 'DATA',
        UDP_PING: 'UDP_PING',
        UDP_PONG: 'UDP_PONG'
    }

    # precalculated data lengths
    headerLength = struct.calcsize('>hh')
    shortLength = struct.calcsize('>h')

    @staticmethod
    def parseHeader(data):
        """Returns a (length, type) tuple."""
        return struct.unpack_from('>hh', data, 0)

    @staticmethod
    def readRawPacket(sock):
        """ """
        data = ''

        while len(data) != Packet.shortLength * 2:
            tmp = sock.recv(Packet.shortLength * 2 - len(data))
            if not tmp:
                return None

            data += tmp

        (packetType, length,) = struct.unpack('>hh', data)
        # print "packet type: %d, length: %d" % (packetType, length)

        data = ''
        while len(data) != length:
            tmp = sock.recv(length - len(data))
            if not tmp:
                return (None, None)

            data += tmp

        return (packetType, data)


def name(packetType):
    if not Packet.packetNames.has_key(packetType):
        return '<UNKNOWN>'

    return Packet.packetNames[packetType]


class LoginPacket(Packet):
    def __init__(self, name):
        nameLength = len(name)
        packetLength = struct.calcsize('>h') + nameLength
        self.message = struct.pack('>hhh%ds' % nameLength, Packet.LOGIN, packetLength, nameLength, name)
        # self.message = struct.pack( '>hhhIII', struct.calcsize( '>hhIII' ), Packet.LOGIN, tag, id, secret, version )


class AnnounceGamePacket(Packet):
    def __init__(self, scenarioId):
        # create the message
        self.message = struct.pack('>hhh', Packet.ANNOUNCE, Packet.shortLength, scenarioId)


class LeaveGamePacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.LEAVE_GAME, 0)


class JoinGamePacket(Packet):
    def __init__(self, id):
        length = struct.calcsize('>I')
        self.message = struct.pack('>hhI', Packet.JOIN_GAME, length, id)


class DataPacket(Packet):
    def __init__(self, data):
        # create the message
        dataLength = len(data)
        self.message = struct.pack('>hh%ds' % dataLength, Packet.DATA, dataLength, data)


class UdpPingPacket(Packet):
    def __init__(self):
        now = datetime.datetime.now()
        milliseconds = (now.day * 24 * 60 * 60 + now.second) * 1000 + now.microsecond / 1000
        print "ms: ", milliseconds
        # create the message
        self.message = struct.pack('>hL', Packet.UDP_PING, milliseconds)




# class PongPacket(Packet):
#     def __init__(self):
#         # create the message
#         self.message = struct.pack('>hh', Packet.shortLength, Packet.PONG)
#
#
#
#
# class UdpDataPacket(Packet):
#     def __init__(self, playerId, gameId, data):
#         # create the message
#         dataLength = len(data)
#         packetLength = struct.calcsize('>hh') + dataLength
#         self.message = struct.pack('>hhh%ds' % dataLength, packetLength, playerId, gameId, data)
#
#
# class StartActionPacket(Packet):
#     def __init__(self):
#         # create the message
#         self.message = struct.pack('>h', Packet.START_ACTION)
