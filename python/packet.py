import struct
import datetime


class Packet:
    LOGIN = 0  # to server
    LOGIN_OK = 1  # from server
    INVALID_PROTOCOL = 2
    INVALID_NAME = 3
    NAME_TAKEN = 4
    SERVER_FULL = 5
    ANNOUNCE = 6  # to server
    ANNOUNCE_OK = 7
    ALREADY_ANNOUNCED = 8
    GAME_ADDED = 9
    GAME_REMOVED = 10
    LEAVE_GAME = 11
    NO_GAME = 12
    JOIN_GAME = 13
    GAME_JOINED = 14
    INVALID_GAME = 15
    ALREADY_HAS_GAME = 16
    GAME_FULL = 17
    GAME_ENDED = 18
    DATA = 19
    READY_TO_START = 20

    UDP_PING = 21
    UDP_PONG = 22
    UDP_DATA = 23
    UDP_DATA_START_ACTION = 24

    UDP_DATA_MISSION = 200
    UDP_DATA_UNIT_STATS = 201

    packetNames = {
        LOGIN: 'LOGIN',
        LOGIN_OK: 'LOGIN_OK',
        INVALID_PROTOCOL: 'INVALID_PROTOCOL',
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
        READY_TO_START: 'READY_TO_START',
        UDP_PING: 'UDP_PING',
        UDP_PONG: 'UDP_PONG',
        UDP_DATA_START_ACTION: 'UDP_DATA_START_ACTION',
        UDP_DATA: 'UDP_DATA',
        UDP_DATA_MISSION: 'UDP_DATA_MISSION',
        UDP_DATA_UNIT_STATS: 'UDP_DATA_UNIT_STATS',
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
    def __init__(self, protocolVersion, name):
        nameLength = len(name)
        packetLength = struct.calcsize('>hh') + nameLength
        self.message = struct.pack('>hhhh%ds' % nameLength, Packet.LOGIN, packetLength, protocolVersion, nameLength, name)


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


class ReadyToStartPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.READY_TO_START, 0)


class UdpPingPacket(Packet):
    def __init__(self):
        now = datetime.datetime.now()
        milliseconds = (now.day * 24 * 60 * 60 + now.second) * 1000 + now.microsecond / 1000
        # create the message
        self.message = struct.pack('>hL', Packet.UDP_PING, milliseconds)


class UdpTextPacket(Packet):
    def __init__(self, type, data):
        # create the message
        dataLength = len(data)
        self.message = struct.pack('>hh%ds' % dataLength, Packet.UDP_DATA, type, data)


class UdpDataPacket(Packet):
    def __init__(self, type, value):
        # create the message
        self.message = struct.pack('>hhh', Packet.UDP_DATA, type, value)




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
