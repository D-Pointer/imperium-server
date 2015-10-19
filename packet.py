
import struct

class Packet:

    INFO         = 0

    # handle games
    ANNOUNCE     = 1
    JOIN         = 2 
    LEAVE        = 3  
    STARTS       = 4 
    ENDS         = 5

    # game info
    GET_GAMES    = 6
    #GAME_COUNT   = 7
    GAME         = 8

    # player info
    GET_PLAYERS  = 9
    PLAYER_COUNT = 10
    PLAYER       = 11

    # ping
    PING         = 12
    PONG         = 13

    # result codes
    OK           = 14
    ERROR        = 15

    # generic data
    DATA         = 16

    packetNames = ('INFO', 'ANNOUNCE', 'JOIN', 'LEAVE', 'STARTS', 'ENDS', 'GET_GAMES', 'GAME_COUNT', 'GAME', 'GET_PLAYERS', 'PLAYER_COUNT', 'PLAYER', 'PING', 'PONG', 'OK', 'ERROR', 'DATA')

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
    if packetType < 0 or packetType >= len(Packet.packetNames):
        return '<UNKNOWN>'

    return Packet.packetNames[ packetType ]


class InfoPacket (Packet):
    def __init__ (self, name, version):
        name = name.encode('ascii')
        length = struct.calcsize( '>hIh' ) + len(name)
        self.message = struct.pack( '>hhIh%ds' % len(name), length, Packet.INFO, version, len(name), name )


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


