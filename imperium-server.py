#! /usr/bin/env python

import logging
import logging.handlers
import sys
import asyncore
import socket

from player_handler import PlayerHandler
from player_manager import PlayerManager
from game_manager   import GameManager
from registration_manager import RegistrationManager

logFileName = 'log/imperium-server.log'
maxLogFileSize = 2000

class ImperiumServer(asyncore.dispatcher):
    """Main server class."""
    def __init__(self, port, logger):
        asyncore.dispatcher.__init__(self)

        self.logger = logger

        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.set_reuse_addr()
        self.bind(('', port))
        self.listen(5)

        # player manager for handling all players
        self.playerManager = PlayerManager( logger )

        # game manager for handling all games
        self.gameManager = GameManager( logger )

        # registration manager for handling authentication
        self.registrationManager = RegistrationManager( logger )


    def handle_accept(self):
        pair = self.accept()
        if pair is not None:
            sock, addr = pair
            self.logger.debug( 'incoming connection from %s' % repr(addr) )
            handler = PlayerHandler( sock, self.logger, self.playerManager, self.gameManager, self.registrationManager )

            self.playerManager.addPlayer( handler )
            self.logger.info( 'added player, now: %d' % self.playerManager.getPlayerCount() )


if __name__ == '__main__':
    if len( sys.argv ) != 2:
        print 'Missing arguments, usage %s tcp_port' % sys.argv[0]
        sys.exit( 1 )

    try:
        port = int ( sys.argv[1] )
    except:
        print 'Invalid port: %s' % sys.argv[1]
        sys.exit( 1 )


    # log record format string
    formatString = '%(asctime)s %(levelname)s %(module)s.%(funcName)s: %(message)s'

    # set default logging (to console)
    logging.basicConfig( level=logging.DEBUG, format=formatString )

    # set logging to file
    fileHandler = logging.handlers.TimedRotatingFileHandler( logFileName, when='midnight', backupCount=30 )
    fileHandler.setFormatter( logging.Formatter( formatString ) )

    # create our logger
    logger = logging.getLogger()
    logger.addHandler( fileHandler )

    # create the real server
    server = ImperiumServer( port, logger )

    try:
        logger.info('starting main loop')
        asyncore.loop()
    except KeyboardInterrupt:
        print 'Interrupted, exiting'
    finally:
        # perform an orderly shutdown by flushing and closing all handlers; called at application exit and no further use of the logging system should be made after this call.
        logging.shutdown()

