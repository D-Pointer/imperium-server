import struct
import datetime


class Packet:
    # TCP packets
    LOGIN = 0  # to server
    LOGIN_OK = 1  # from server
    INVALID_PROTOCOL = 2
    ALREADY_LOGGED_IN = 3
    INVALID_NAME = 4
    NAME_TAKEN = 5
    SERVER_FULL = 6
    ANNOUNCE = 7  # to server
    ANNOUNCE_OK = 8
    ALREADY_ANNOUNCED = 9
    GAME_ADDED = 10
    GAME_REMOVED = 11
    LEAVE_GAME = 12
    NO_GAME = 13
    JOIN_GAME = 14
    GAME_JOINED = 15
    INVALID_GAME = 16
    ALREADY_HAS_GAME = 17
    GAME_FULL = 18
    GAME_ENDED = 19
    DATA = 20
    READY_TO_START = 21
    KEEP_ALIVE_PACKET = 22
    PLAYER_COUNT_PACKET = 23

    # TCP sub packets
    SETUP_UNITS = 0
    GAME_RESULT = 1
    WIND = 2

    # UDP packets
    UDP_PING = 0
    UDP_PONG = 1
    UDP_DATA = 2
    UDP_DATA_START_ACTION = 3

    # UDP sub packets
    UDP_DATA_MISSION = 0
    UDP_DATA_UNIT_STATS = 1
    UDP_DATA_FIRE = 2
    UDP_DATA_MELEE = 3
    UDP_DATA_SET_MISSION = 4
    UDP_DATA_PLAYER_PING = 5
    UDP_DATA_PLAYER_PONG = 6
    UDP_DATA_SMOKE = 7

    packetNames = {
        LOGIN: 'LOGIN',
        LOGIN_OK: 'LOGIN_OK',
        INVALID_PROTOCOL: 'INVALID_PROTOCOL',
        ALREADY_LOGGED_IN: 'ALREADY_LOGGED_IN',
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
        KEEP_ALIVE_PACKET: 'KEEP_ALIVE_PACKET',
        PLAYER_COUNT_PACKET: 'PLAYER_COUNT_PACKET'
    }

    # precalculated data lengths
#    headerLength = struct.calcsize('>hh')
    shortLength = struct.calcsize('>h')

#    @staticmethod
#    def parseHeader(data):
#        """Returns a (length, type) tuple."""
#        return struct.unpack_from('>hh', data, 0)

    @staticmethod
    def readRawPacket(sock):
        """ """
        data = ''

        while len(data) != Packet.shortLength * 2:
            tmp = sock.recv(Packet.shortLength * 2 - len(data))
            #tmp = sock.recv( Packet.shortLength )
            if not tmp:
                return None

            data += tmp

        (length, packetType,) = struct.unpack('!HH', data)

        # the length contains the packet type which we've already read, so skip that
        length -= Packet.shortLength

        packetName = name(packetType)

        #print "packet type: %d, name: %s, length: %d" % (packetType, packetName, length)

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
    def __init__(self, protocolVersion, name, password):
        nameLength = len(name)
        passLength = len(password)
        packetLength = struct.calcsize('>hhhh') + nameLength + passLength
        self.message = struct.pack('>hhhh%dsh%ds' % (nameLength, passLength), packetLength, Packet.LOGIN, protocolVersion, nameLength, name, passLength, password)


class AnnounceGamePacket(Packet):
    def __init__(self, scenarioId):
        # create the message
        length = struct.calcsize('>hh')
        self.message = struct.pack('>hhh', length, Packet.ANNOUNCE, scenarioId)


class LeaveGamePacket(Packet):
    def __init__(self):
        # create the message
        length = struct.calcsize('>h')
        self.message = struct.pack('>hh', length, Packet.LEAVE_GAME )


class JoinGamePacket(Packet):
    def __init__(self, id):
        length = struct.calcsize('>hI')
        self.message = struct.pack('>hhI', length, Packet.JOIN_GAME, id)


class DataPacket(Packet):
    def __init__(self, data):
        # create the message
        dataLength = len(data)
        packetLength = struct.calcsize('>h') + dataLength
        self.message = struct.pack('>hh%ds' % dataLength, packetLength, Packet.DATA, data)


class ReadyToStartPacket(Packet):
    def __init__(self):
        # create the message
        self.message = struct.pack('>hh', Packet.READY_TO_START, 0)


class SendUnitsPacket(Packet):
    def __init__(self, units):
        # get a list of all the unit datas and create a single string from it
        unitData = reduce( lambda d1, d2: d1 + d2, map( lambda u: u.getData(), units ) )

        # combined length of all the datas
        dataLength = len( unitData )

        print "data length: %d" % dataLength

        # create the message
        self.message = struct.pack('>hhBB%ds' % dataLength, Packet.DATA, struct.calcsize('>BB') + dataLength, Packet.SETUP_UNITS & 0xff, len(units) & 0xff, unitData )


class EndGameGamePacket(Packet):
    def __init__(self, endType, total1, total2, lost1, lost2, objectives1, objectives2):
        data = struct.pack( '>BBhhhhhh', Packet.GAME_RESULT, endType, total1, total2, lost1, lost2, objectives1, objectives2)
        dataLength = len( data )

        self.message = struct.pack('>hh%ds' % dataLength, Packet.DATA, dataLength, data )


# UDP packets

class UdpPingPacket(Packet):
    def __init__(self, playerId):
        now = datetime.datetime.now()
        milliseconds = (now.day * 24 * 60 * 60 + now.second) * 1000 + now.microsecond / 1000
        # create the message
        self.message = struct.pack('>BIL', 0x0, playerId, milliseconds)


class UdpDataPacket(Packet):
    def __init__(self, playerId, value):
        dataLength = len( value )
        # create the message
        self.message = struct.pack('>BI%ds' % dataLength, Packet.UDP_DATA & 0xff, playerId, value)


class UdpMissionPacket(Packet):
    def __init__(self, units, packetId):
        missionData = reduce( lambda d1, d2: d1 + d2, map( lambda unit: struct.pack('>hB', unit.id, unit.mission), units))

        # combined length of all the datas
        dataLength = len( missionData )

        # create the message
        self.message = struct.pack('>BBIB%ds' % dataLength, Packet.UDP_DATA & 0xff, Packet.UDP_DATA_MISSION & 0xff, packetId, len(units), missionData)


class UdpUnitStatsPacket(Packet):
    def __init__(self, units, packetId):
        # get a list of all the unit datas and create a single string from it
        statsData = reduce( lambda d1, d2: d1 + d2, map( lambda u: u.getStats(), units ) )

        # combined length of all the datas
        dataLength = len( statsData )

        # create the message
        self.message = struct.pack('>BBIB%ds' % dataLength, Packet.UDP_DATA & 0xff, Packet.UDP_DATA_UNIT_STATS & 0xff, packetId, len(units), statsData )


class UdpFirePacket(Packet):
    def __init__(self, attackerId, hitX, hitY, casualties, packetId):
        if casualties and len( casualties ) > 0:
            # get a list of all the casualties and create a single string from it
            casualtiesData = reduce( lambda d1, d2: d1 + d2, map( lambda c: struct.pack('>hBBhh', *c), casualties ) )
            dataLength = len( casualtiesData )
            print "data length: %d" % dataLength

            self.message = struct.pack('>BBIhhhB%ds' % dataLength, Packet.UDP_DATA & 0xff, Packet.UDP_DATA_FIRE & 0xff, packetId, attackerId, hitX, hitY, len(casualties), casualtiesData )

        else:
            # no casualties
            self.message = struct.pack('>BBIhhhB', Packet.UDP_DATA & 0xff, Packet.UDP_DATA_FIRE & 0xff, packetId, attackerId, hitX, hitY, 0 )


class UdpPlayerPongPacket(Packet):
    def __init__(self, ms, packetId):
        # create the message
        self.message = struct.pack('>BBIL', Packet.UDP_DATA & 0xff, Packet.UDP_DATA_PLAYER_PONG & 0xff, packetId, ms)

