
import logging
import string

from player import Player

class RegistrationManager:

    def __init__ (self):
        # no players yet
        self.players = {}
        self.used_names = []

        self.logger = logging.getLogger('RegistrationManager')

        # start from 1 as 0 is used in Imperium to mean "no id"
        self.nextId = 1

        # read in all players
        for line in open( 'players.db').readlines():
            parts = line.split(' ')

            id = int( parts[0] )
            secret = int( parts[-1] )
            name = string.join( parts[1:-1] )

            player = Player( id, name, secret )
            self.players[ id ] = player

            #self.logger.debug( 'player: %s', player )

            # also cache the name as used
            self.used_names.append( name )

            # new largest id?
            self.nextId = max( self.nextId, id + 1 )

        self.logger.info( '__init__: loaded %d players', len( self.players ))


    def register (self, name, secret):
        if name in self.used_names:
            return None

        id = self.nextId
        self.nextId += 1

        # save the player
        player = Player( id, name, secret )
        self.players[ id ] = player

        # also cache the name as used
        self.used_names.append( name )

        # save the new player
        file = open( 'players.db', 'a')
        file.write( '%d %s %d\n' %( id, name, secret ) )
        file.close()

        self.logger.debug( 'register: players: %d', len( self.players ) )

        return player


    def getPlayer (self, id, secret):
        if not self.players.has_key( id ):
            self.logger.warning( 'getPlayer: no player with id %d', id )
            return None

        player = self.players[ id ]

        # correct secret?
        if player.secret != secret:
            self.logger.warning( 'getPlayer: secret does not match: %d != %d', secret, player.secret )
            return None

        return player
