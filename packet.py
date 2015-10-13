
import struct

class Packet:

    INFO         = 0

    # handle games
    ANNOUNCE     = 1
    JOIN         = 2 
    LEAVE        = 3  
    STARTS       = 4 

    # game info
    GET_GAMES    = 5
    GAME_COUNT   = 6
    GAME         = 7

    # player info
    GET_PLAYERS  = 8
    PLAYER_COUNT = 9
    PLAYER       = 10

    # ping
    PING         = 11
    PONG         = 12 

    # result codes
    OK           = 13
    ERROR        = 14

    # generic data
    DATA         = 15

    packetNames = ('INFO', 'ANNOUNCE', 'JOIN', 'LEAVE', 'STARTS', 'GET_GAMES', 'GAME_COUNT', 'GAME', 'GET_PLAYERS', 'PLAYER_COUNT', 'PLAYER', 'PING', 'PONG', 'OK', 'ERROR', 'DATA')

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
            tmp = sock.recv( Packet.shortLength )
            if not tmp:
                return None

            data += tmp

        (length, ) = struct.unpack( '>h', data )
        #print "packet length:", length

        data = ''
        while len(data) != length:
            tmp = sock.recv( length )
            if not tmp:
                return None

            data += tmp

        return data


def name (packetType):
    if packetType < 0 or packetType > Packet.ERROR:
        return '<UNKNOWN>'

    return Packet.packetNames[ packetType ]


class InfoPacket (Packet):
    def __init__ (self, name, playerId, version):
        name = name.encode('ascii')
        length = struct.calcsize( '>hhIh' ) + len(name)
        self.message = struct.pack( '>hhhIh%ds' % len(name), length, Packet.INFO, playerId, version, len(name), name )


class GetPlayersPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.GET_PLAYERS )


class GetGamesPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.GET_GAMES )


class AnnounceGamePacket (Packet):
    def __init__ (self, scenarioId):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.ANNOUNCE, scenarioId )


class JoinGamePacket (Packet):
    def __init__ (self, gameId):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.JOIN, gameId )


class LeaveGamePacket (Packet):
    def __init__ (self, gameId):
        # create the message
        self.message = struct.pack( '>hhh', Packet.shortLength * 2, Packet.LEAVE, gameId )


class PingPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.PING )


class PongPacket (Packet):
    def __init__ (self):
        # create the message
        self.message = struct.pack( '>hh', Packet.shortLength, Packet.PONG )


