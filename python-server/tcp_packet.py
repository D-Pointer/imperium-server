
class TcpPacket:
    # TCP packets
    LOGIN = 0  # to server
    LOGIN_OK = 1  # from server
    INVALID_PROTOCOL = 2  # from
    ALREADY_LOGGED_IN = 3  # from
    INVALID_NAME = 4  # from
    NAME_TAKEN = 5  # from
    SERVER_FULL = 6  # from
    ANNOUNCE = 7  # to
    ANNOUNCE_OK = 8 # from
    ALREADY_ANNOUNCED = 9 # from
    GAME_ADDED = 10 # from
    GAME_REMOVED = 11 # from
    LEAVE_GAME = 12 # to
    NO_GAME = 13 # from
    JOIN_GAME = 14 # to
    GAME_JOINED = 15 # from
    INVALID_GAME = 16 # from
    ALREADY_HAS_GAME = 17 # from
    GAME_FULL = 18 # from
    GAME_ENDED = 19 # from
    DATA = 20 # to
    READY_TO_START = 21 # to
    GET_RESOURCE_PACKET = 22 # to
    RESOURCE_PACKET = 23 # from
    INVALID_RESOURCE_NAME_PACKET = 24 # from
    INVALID_RESOURCE_PACKET = 25 # from
    KEEP_ALIVE_PACKET = 26 # to
    PLAYER_COUNT_PACKET = 27 # from
    INVALID_PASSWORD_PACKET = 28 # from

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
        GET_RESOURCE_PACKET: 'GET_RESOURCE_PACKET',
        RESOURCE_PACKET: 'RESOURCE_PACKET',
        INVALID_RESOURCE_NAME_PACKET: 'INVALID_RESOURCE_NAME_PACKET',
        INVALID_RESOURCE_PACKET: 'INVALID_RESOURCE_PACKET',
        KEEP_ALIVE_PACKET: 'KEEP_ALIVE_PACKET',
        PLAYER_COUNT_PACKET: 'PLAYER_COUNT_PACKET',
        INVALID_PASSWORD_PACKET: 'INVALID_PASSWORD_PACKET'
    }


    @staticmethod
    def name(packetType):
        if not TcpPacket.packetNames.has_key(packetType):
            return '<UNKNOWN>'

        return TcpPacket.packetNames[packetType]
