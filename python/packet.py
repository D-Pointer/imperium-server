import struct


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

    JOIN = 2
    LEAVE = 3
    GET_GAMES = 6
    GET_PLAYERS = 9
    GET_PLAYER_COUNT = 33
    PING = 12
    SUBSCRIBE = 30
    UNSUBSCRIBE = 31

    # sent by both
    DATA = 16

    # UDP packets
    START_ACTION = 200
    DUMMY = 201
    MISSION = 202
    UNIT_STATS = 203

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


class OkPacket(Packet):
    def __init__(self, tag=0):
        self.message = struct.pack('>hhh', Packet.shortLength * 2, Packet.OK, tag)


class ErrorPacket(Packet):
    def __init__(self, tag=0):
        self.message = struct.pack('>hhh', Packet.shortLength * 2, Packet.ERROR, tag)


class RegisterPacket(Packet):
    def __init__(self, tag, name, secret):
        nameLength = len(name)
        packetLength = struct.calcsize('>hhIh') + nameLength
        self.message = struct.pack('>hhhIh%ds' % nameLength, packetLength, Packet.REGISTER, tag, secret, nameLength,
                                   name)


class RegisterOkPacket(Packet):
    def __init__(self, tag, id):
        length = struct.calcsize('>hhI')
        self.message = struct.pack('>hhhI', length, Packet.REGISTER_OK, tag, id)


class GetPlayerCountPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength, Packet.GET_PLAYER_COUNT)


class GetPlayersPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength, Packet.GET_PLAYERS)


class GetGamesPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength, Packet.GET_GAMES)


class JoinGamePacket(Packet):
    def __init__(self, gameId):
        # create the message
        self.message = struct.pack('>hhh', Packet.shortLength * 2, Packet.JOIN, gameId)


class LeaveGamePacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength * 2, Packet.LEAVE)


class PingPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength, Packet.PING)


class PongPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.shortLength, Packet.PONG)


class SubscribePacket(Packet):
    def __init__(self, tag):
        # create the message
        self.message = struct.pack('>hhh', Packet.shortLength * 2, Packet.SUBSCRIBE, tag)


class UnsubscribePacket(Packet):
    def __init__(self, tag):
        # create the message
        self.message = struct.pack('>hhh', Packet.shortLength * 2, Packet.UNSUBSCRIBE, tag)


class DataPacket(Packet):
    def __init__(self, data):
        # create the message
        dataLength = len(data)
        packetLength = struct.calcsize('>hhh') + dataLength
        self.message = struct.pack('>hhh%ds' % dataLength, packetLength, Packet.DATA, dataLength, data)


class UdpDataPacket(Packet):
    def __init__(self, playerId, gameId, data):
        # create the message
        dataLength = len(data)
        packetLength = struct.calcsize('>hh') + dataLength
        self.message = struct.pack('>hhh%ds' % dataLength, packetLength, playerId, gameId, data)


class StartActionPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>h', Packet.START_ACTION)
