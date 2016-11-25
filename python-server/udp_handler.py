
from twisted.internet.protocol import DatagramProtocol
import socket
import struct
import datetime

import udp_packet

class UdpHandler (DatagramProtocol):

    PACKET_TYPE_SIZE = struct.calcsize( '!B' )

    def __init__(self, statistics, logger, reactor):
        self.statistics = statistics
        self.logger = logger

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
        self.logger.info( "start UDP protocol" )


    def datagramReceived(self, data, addr):
        self.logger.debug("received %d bytes from %s", len(data), addr )

        # save the address if needed
        if self.address == None:
            self.address = addr

        offset = 0
        packetType, = struct.unpack_from( '!B', data, 0 )
        offset += UdpHandler.PACKET_TYPE_SIZE

        if packetType == udp_packet.UdpPacket.PING:
            timestamp, = struct.unpack_from( '!I', data, offset )
            self.logger.debug( "sending pong to %s:%d for timestamp %d", addr[0], addr[1], timestamp )
            response = struct.pack( '!BI', udp_packet.UdpPacket.PONG, timestamp )
            self.transport.write( response, addr )

            # update statistics
            self.statistics.lock()
            self.statistics.udpBytesReceived += len(data)
            self.statistics.udpBytesSent += len(response)
            self.statistics.udpLastReceived = datetime.datetime.now()
            self.statistics.udpLastSent = self.statistics.udpLastReceived
            self.statistics.release()

        elif packetType == udp_packet.UdpPacket.DATA:
            # precautions
            if not self.opponent.address:
                self.logger.warn( "no opponent UDP handler yet" )
            else:
                self.opponent.transport.write( data, self.opponent.address )

                # update statistics
                self.statistics.lock()
                self.statistics.udpPacketsReceived += 1
                self.statistics.udpBytesReceived += len(data)
                self.statistics.udpLastReceived = datetime.datetime.now()
                self.statistics.release()

                # opponent stats
                self.opponent.statistics.lock()
                self.opponent.statistics.udpPacketsSent += 1
                self.opponent.statistics.udpBytesSent += len(data)
                self.opponent.statistics.udpLastSent = self.statistics.udpLastReceived
                self.opponent.statistics.release()


    def cleanup (self):
        self.logger.debug( "cleaning up UDP connection to %s:%d", self.address[0], self.address[1] )
        if self.socket:
            self.socket.close()
            self.socket = None

        self.opponent = None
        self.port = None


    def getLocalPort(self):
        return self.socket.getsockname()[ 1 ]


    def sendStartPackets (self):
        self.logger.debug("TODO: send to us and opponent" )