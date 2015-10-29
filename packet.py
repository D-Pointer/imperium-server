
import struct

class Packet:

    # sent by the players
    INFO         = 0
    ANNOUNCE     = 1
    JOIN         = 2
    LEAVE        = 3
    GET_GAMES    = 6
    GET_PLAYERS  = 9
    PING         = 12
    SUBSCRIBE    = 30
    UNSUBSCRIBE  = 31

    # sent by the server
    STARTS       = 4
    GAME_ADDED   = 20
    GAME_REMOVED = 21
    GAMES        = 8
    PLAYER_COUNT = 10
    PLAYER       = 11
    PONG         = 13
    OK           = 14
    ERROR        = 15
    START_ACTION = 32

    # sent by both
    DATA         = 16

    packetNames = { INFO:         'INFO',
                    ANNOUNCE:     'ANNOUNCE',
                    JOIN:         'JOIN',
                    LEAVE:        'LEAVE',
                    STARTS:       'STARTS',
                    GET_GAMES:    'GET_GAMES',
                    GAMES:        'GAMES',
                    GET_PLAYERS:  'GET_PLAYERS',
                    PLAYER_COUNT: 'PLAYER_COUNT',
                    PLAYER:       'PLAYER',
                    PING:         'PING',
                    PONG:         'PONG',
                    OK:           'OK',
                    ERROR:        'ERROR',
                    DATA:         'DATA',
                    GAME_ADDED:   'GAME_ADDED',
                    GAME_REMOVED: 'GAME_REMOVED',
                    SUBSCRIBE:    'SUBSCRIBE',
                    UNSUBSCRIBE:  'UNSUBSCRIBE',
                    START_ACTION: 'START_ACTION',
                    }

    # precalculated data lengths
    headerLength = struct.calcsize( '>hh' )
    shortLength  = struct.calcsize( '>h' )

    @staticmethod
    def parseHeader (data):        
        """Returns a (length, type) tuple."""
        return struct.unpack_from( '>hh', data, 0 )


    @staticmethod
    def readRawPacket (sock):
        """ """
        data = ''

        while len(data) != Packet.shortLength:
            tmp = sock.recv( Packet.shortLength - len(data) )
            if not tmp:
                return None

            data += tmp

        (length, ) = struct.unpack( '>h', data )
        #print "packet length:", length

        data = ''
        while len(data) != length:
            tmp = sock.recv( length - len(data) )
            if not tmp:
                return None

            data += tmp

        return data


def name (packetType):
    if not Packet.packetNames.has_key(packetType):
        return '<UNKNOWN>'

    return Packet.packetNames[ packetType ]


class OkPacket (Packet):
    def __init__ (self, tag=0):
         self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.OK, tag )


class ErrorPacket (Packet):
    def __init__ (self, tag=0):
         self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.ERROR, tag )


class InfoPacket (Packet):
    def __init__ (self, name, version, tag):
        name = name.encode('ascii')
        length = struct.calcsize( '>hhIh' ) + len(name)
        self.message = struct.pack( '>hhhIh%ds' % len(name), length, Packet.INFO, tag, version, len(name), name )


class GetPlayersPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.GET_PLAYERS )


class GetGamesPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.GET_GAMES )


class AnnounceGamePacket (Packet):
    def __init__ (self, scenarioId, tag):
        # create the message
        self.message = struct.pack( '>hhhh', Packet.shortLength * 3, Packet.ANNOUNCE, scenarioId, tag )


class JoinGamePacket (Packet):
    def __init__ (self, gameId):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.JOIN, gameId )


class LeaveGamePacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength * 2, Packet.LEAVE )


class PingPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.PING )


class PongPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.PONG )


class SubscribePacket (Packet):
    def __init__ (self, tag):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.SUBSCRIBE, tag )


class UnsubscribePacket (Packet):
    def __init__ (self, tag):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.UNSUBSCRIBE, tag )


class DataPacket (Packet):
    def __init__ (self, data):
        # create the message
        dataLength = len(data)
        packetLength = struct.calcsize( '>hhh' ) + dataLength
        self.message = struct.pack( '>hhh%ds' % dataLength, packetLength, Packet.DATA, dataLength, data )


class UdpDataPacket (Packet):
    def __init__ (self, playerId, gameId, data):
        # create the message
        dataLength = len(data)
        packetLength = struct.calcsize( '>hh' ) + dataLength
        self.message = struct.pack( '>hhh%ds' % dataLength, packetLength, playerId, gameId, data )


class StartActionPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>h', Packet.START_ACTION )


