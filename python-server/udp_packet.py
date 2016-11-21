
class UdpPacket:
    # TCP packets
    PING = 0  # to server
    PONG = 1
    DATA = 2
    START_ACTION = 3

    packetNames = {
        PING: 'PING',
        PONG: 'PONG',
        DATA: 'DATA',
        START_ACTION: 'START_ACTION',
    }


    @staticmethod
    def name(packetType):
        if not UdpPacket.packetNames.has_key(packetType):
            return '<UNKNOWN>'

        return UdpPacket.packetNames[packetType]
