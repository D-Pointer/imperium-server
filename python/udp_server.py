
import asyncore
import socket
import packet
import struct

class UdpServer(asyncore.dispatcher):

    def __init__(self, game, logger):
        asyncore.dispatcher.__init__(self)
        self.logger = logger

        self.game = game

        self.create_socket(socket.AF_INET, getSocket.SOCK_DGRAM)
        self.set_reuse_addr()
        self.bind(('', game.udpPort ))

        # the two players
        self.players = []

        # both players logged in?
        self.started = False

        # packets relayed in the full game
        self.packetsSent = 0
        self.bytesSent = 0

        self.logger.debug( 'UDP server initialized, port: %d', game.udpPort )


    def getPacketsSent (self):
        return self.packetsSent


    def getBytesSent (self):
        return self.bytesSent

    def handle_connect(self):
        pass


    def handle_read(self):
        data, addr = self.recvfrom( 512 )

        if not data:
            return

        self.logger.debug( 'received %d bytes from %s', len(data), str(addr) )

        if not self.started:
            # just save the address as the player
            if not addr in self.players:
                self.players.append( addr )

            # do we have both players now?
            if len ( self.players ) == 2:
                self.started = True
                self.logger.debug( 'both players have sent an initial packet, sending START_ACTION' )

                # send a few start action packets
                startActionPacket = packet.StartActionPacket()
                for index in range ( 5 ):
                    self.sendto( startActionPacket.message, self.players[ 0 ] )
                    self.sendto( startActionPacket.message, self.players[ 1 ] )

        else:
            # a custom packet such as ping?
            if self.handleCustomPacket( data, addr ):
                # packet handled
                return

            # already started, just send to the other
            if addr == self.players[0]:
                self.sendto( data, self.players[ 1 ] )
            elif addr == self.players[1]:
                self.sendto( data, self.players[ 0 ] )
            else:
                self.logger.error( 'received a UDP packet from someone not a player: ' + addr )
                return

            self.packetsSent += 1
            self.bytesSent += len( data )


    def handle_write(self):
        pass
        

    def handleCustomPacket (self, data, sender):
        (packetType, ) = struct.unpack_from( '>h', data, 0 )

        # a ping?
        if packetType == packet.Packet.PING:
            (timestamp, ) = struct.unpack_from( '>L', data, packet.Packet.shortLength )
            pong = struct.pack( '>hL', packet.Packet.PONG, timestamp )

            if sender == self.players[0]:
                self.logger.debug( 'sending pong for %d to player 2', timestamp )
                self.sendto( pong, self.players[ 0 ] )
            else:
                self.logger.debug( 'sending pong for %d to player 1', timestamp )

                self.sendto( pong, self.players[ 1 ] )
            

            return True

        # nothing we handle
        return False
