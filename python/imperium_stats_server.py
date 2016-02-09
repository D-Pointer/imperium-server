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
from stats_handler import StatsHandler


class ImperiumStatsServer(asyncore.dispatcher):
    """Stats server class."""
    def __init__(self, port, server, logger):
        asyncore.dispatcher.__init__(self)

        # save all data
        self.server = server
        self.logger = logger

        self.create_socket(socket.AF_INET, getSocket.SOCK_STREAM)
        self.set_reuse_addr()
        self.bind(('', port))
        self.listen(5)

        self.logger.info( 'initialized stats server on port: %d', port )


    def handle_accept(self):
        pair = self.accept()
        if pair is not None:
            sock, addr = pair
            self.logger.info( 'incoming stats connection from %s' % repr(addr) )
            handler = StatsHandler( sock, self.server, self.logger,  )
