
class PlayerManager:

    def __init__ (self, logger):
        # no players yet
        self.players = []

        self.logger = logger


    def addPlayer (self, player):
        self.players.append( player )


    def removePlayer (self, player):
        if player in self.players:
            self.players.remove( player )
            return True

        else:
            self.logger.warning('player %s not found, can not remove' % player )
            return False
            

    def getPlayers (self):
        return self.players


    def getPlayerCount (self):
        return len( self.players )
