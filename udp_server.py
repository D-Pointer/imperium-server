
import sys
import asyncore
import logging
import socket
import struct

import packet

class UdpServer(asyncore.dispatcher):

    def __init__(self, game):
        asyncore.dispatcher.__init__(self)
        self.logger = logging.getLogger('UdpServer-%d' % game.gameId)

        self.game = game

        self.create_socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.set_reuse_addr()
        self.bind(('', game.udpPort ))

        # the two players
        self.players = [ None, None ]

        # both players logged in?
        self.started = False

        self.logger.debug( 'UDP server initialized, port: %d', game.udpPort )


    def handle_connect(self):
        pass


    def handle_read(self):
        data, addr = self.recvfrom( 512 )

        if not data:
            return

        self.logger.debug( 'handle_read: received %d bytes from %s', len(data), str(addr) )

        while data != '':
            (length, playerId, gameId, ) = struct.unpack_from( '>hhh', data, 0 )
            #self.logger.debug( 'handle_read: game %d, sender: %d, content length: %d', gameId, playerId, length )

            # the right game?
            if gameId != self.game.gameId:
                self.logger.warning( 'handle_read: invalid game %d, ignoring', gameId )

            elif not self.started:
                # just save the address as the player
                self.players[ playerId ] = addr
                self.logger.debug( 'handle_read: saving %s as player %d', addr, playerId )
                    
                # do we have both players now?
                if not None in self.players:
                    self.started = True
                    self.logger.debug( 'handle_read: both players have sent an initial packet' )

            else:
                # already started, just send to the other
                if playerId == 0:
                    self.logger.debug( 'handle_read: sending %d bytes to player 2', len(data) )
                    self.sendto( data, self.players[ 1 ] )
                else:
                    self.logger.debug( 'handle_read: sending %d bytes to player 1', len(data) )
                    self.sendto( data, self.players[ 0 ] )

            # strip off the handled data
            data = data[ packet.Packet.shortLength + length : ]

    def handle_write(self):
        pass
        
