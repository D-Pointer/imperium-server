
import sys
import asyncore
import logging
import socket
import struct

class UdpServer(asyncore.dispatcher):

    def __init__(self, game, tokens):
        asyncore.dispatcher.__init__(self)
        self.logger = logging.getLogger('UdpServer-%d' % game.gameId)

        self.create_socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.set_reuse_addr()
        self.bind(('', game.udpPort ))

        # the login tokens
        self.tokens = tokens

        # the two players
        self.players = [None, None]

        # both players logged in?
        self.started = False

        self.logger.debug( 'UDP server initialized, port: %d', game.udpPort )


    def handle_connect(self):
        pass


    def handle_read(self):
        data, addr = self.recvfrom(2048)

        if not data:
            return

        self.logger.debug( 'handle_read: received %d bytes from %s', len(data), str(addr) )

        if not self.started:
            # one player logging in?
            (token, ) = struct.unpack_from( '>h', data, 0 )
            self.logger.debug( 'handle_read: received token %d', token )

            if not token in self.tokens:
                self.logger.warning( 'handle_read: token %d not among tokens, ignoring', token )
                return

            # we got a token from one of the players
            self.players[ self.tokens.index( token ) ] = addr

            # do we have both players now?
            if not None in self.players:
                self.started = True

        else:
            # already started, just send to the other
            if addr == self.players[0]:
                self.logger.debug( 'handle_read: sending data to player 1' )
                self.sendto( self.players[1], data )
            else:
                self.logger.debug( 'handle_read: sending data to player 0' )
                self.sendto( self.players[0], data )

    def handle_write(self):
        pass

