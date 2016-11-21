
from twisted.internet.protocol import DatagramProtocol
import socket
import struct
import udp_packet

class UdpHandler (DatagramProtocol):

    PACKET_TYPE_SIZE = struct.calcsize( '!B' )

    def __init__(self, reactor):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        # Make the port non-blocking and start it listening on any port
        self.socket.setblocking(False)
        self.socket.bind( ('0.0.0.0', 0) )

        # now pass the file descriptor to the reactor and register us as a hamdler
        self.port = reactor.adoptDatagramPort( self.socket.fileno(), socket.AF_INET, self )

        # the address to the own player
        self.address = None

        # the opponent UDP handler
        self.opponent = None


    def startProtocol(self):
        print "start UDP protocol"
        # host = "192.168.1.1"
        # port = 1234
        #
        # self.transport.connect(host, port)
        # print(("now we can only send to host %s port %d" % (host, port)))
        # self.transport.write(b"hello")  # no need for address


    def datagramReceived(self, data, addr):
        print("received %d bytes from %s" % (len(data), addr))
        # save the address if needed
        if self.address == None:
            self.address = addr

        offset = 0
        packetType, = struct.unpack_from( '!B', data, 0 )
        offset += UdpHandler.PACKET_TYPE_SIZE

        if packetType == udp_packet.UdpPacket.PING:
            timestamp, = struct.unpack_from( '!I', data, offset )
            print "sending pong to %s:%d for timestamp %d" % (addr[0], addr[1], timestamp )
            response = struct.pack( '!BI', udp_packet.UdpPacket.PONG, timestamp )
            self.transport.write( response, addr )

        elif packetType == udp_packet.UdpPacket.DATA:
            self.opponent.transport.write( data, self.opponent.address )


    def cleanup (self):
        print "cleaning up UDP connection to %s:%d" % self.address
        #self.transport.loseConnection()
        if self.socket:
            self.socket.close()
            self.socket = None

        self.opponent = None
        self.port = None


    def getLocalPort(self):
        return self.socket.getsockname()[ 1 ]


    def sendStartPackets (self):
        print "sendStartPackets: send to us and opponent"