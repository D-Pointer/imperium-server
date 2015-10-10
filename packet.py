
import struct

class Packet:

    INFO         = 0

    # handle games
    ANNOUNCE     = 1
    JOIN         = 2 
    LEAVE        = 3  

    # game info
    GET_GAMES    = 4
    GAME_COUNT   = 5
    GAME         = 6

    # player info
    GET_PLAYERS  = 7
    PLAYER_COUNT = 8
    PLAYER       = 9

    # ping
    PING         = 10
    PONG         = 11 

    # result codes
    OK           = 12
    ERROR        = 13

    # precalculated data lengths
    headerLength = struct.calcsize( '>hh' )
    shortLength  = struct.calcsize( '>h' )

    @staticmethod
    def name (packetType):
        if packetType < 0 or packetType > Packet.ERROR:
            return '<UNKNOWN>'

        return ('INFO', 'ANNOUNCE', 'JOIN', 'LEAVE', 'GET_GAMES', 'GAME_COUNT', 'GAME', 'GET_PLAYERS', 'PLAYER_COUNT', 'PLAYER', 'PING', 'PONG', 'OK', 'ERROR')[ packetType ]


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


