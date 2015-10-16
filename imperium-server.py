#! /usr/bin/env python

import logging
import sys
import asyncore
import socket

from player_handler import PlayerHandler
from player_manager import PlayerManager
from game_manager   import GameManager

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(name)s: %(message)s',
                    )


class ImperiumServer(asyncore.dispatcher):

    def __init__(self, port):
        asyncore.dispatcher.__init__(self)
        self.logger = logging.getLogger('ImperiumServer')
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.set_reuse_addr()
        self.bind(('', port))
        self.listen(5)

        # player manager for handling all players
        self.playerManager = PlayerManager()

        # game manager for handling all games
        self.gameManager = GameManager()


    def handle_accept(self):
        pair = self.accept()
        if pair is not None:
            sock, addr = pair
            self.logger.debug( 'handle_accept: incoming connection from %s' % repr(addr) )
            handler = PlayerHandler( sock , self.playerManager, self.gameManager )

            self.playerManager.addPlayer( handler )
            self.logger.debug( 'handle_accept: players now: %d' % self.playerManager.getPlayerCount() )


if __name__ == '__main__':
    if len( sys.argv ) != 2:
        print 'Missing arguments, usage %s tcpPort' % sys.argv[0]
        sys.exit( 1 )

    port = int ( sys.argv[1] )
    server = ImperiumServer( port )

    try:
        logging.debug('starting main loop')
        asyncore.loop()
    except KeyboardInterrupt:
        print 'Interrupted, exiting'
        pass

