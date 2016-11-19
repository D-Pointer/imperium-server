
from twisted.internet.protocol import DatagramProtocol
import socket

class UdpHandler (DatagramProtocol):

    def __init__(self, reactor):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        # Make the port non-blocking and start it listening on any port
        self.socket.setblocking(False)
        self.socket.bind( ('0.0.0.0', 0) )

        # now pass the file descriptor to the reactor and register us as a hamdler
        self.port = reactor.adoptDatagramPort( self.socket.fileno(), socket.AF_INET, self )


    def startProtocol(self):
        print "start protocol"
        # host = "192.168.1.1"
        # port = 1234
        #
        # self.transport.connect(host, port)
        # print(("now we can only send to host %s port %d" % (host, port)))
        # self.transport.write(b"hello")  # no need for address


    def datagramReceived(self, data, addr):
        print("received %r from %s" % (data, addr))


    def cleanup (self):
        print "cleanup"
        self.transport.close()
        if self.socket:
            self.socket.close()
            self.socket = None


    def getLocalPort(self):
        self.port


    def sendStartPackets (self):
        print "sendStartPackets: send to us and opponent"