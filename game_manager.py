
import logging

class GameManager:

    def __init__ (self):
        # no games yet
        self.announcedGames = []
        self.activeGames = []

        self.logger = logging.getLogger('GameManager')


    def getGame (self, gameId):
        for game in self.announcedGames:
            if game.gameId == gameId:
                return game

        for game in self.activeGames:
            if game.gameId == gameId:
                return game

        return None


    def addGame (self, game):
        self.announcedGames.append( game )


    def removeGame (self, game):
        if game in self.announcedGames:
            self.announcedGames.remove( game )

        elif game in activeGames:
            self.activeGames.remove( game )

        else:
            self.logger.warning('removeGame: game %s not found, can not remove' % game )


    def activateGame (self, game):
        if game in self.announcedGames:
            self.announcedGames.remove( game )
            self.activeGames.append( game )
            self.logger.debug( 'activateGame: game %s activated, active games now %d' % ( game, len(self.activeGames) ) )
        else:
            self.logger.warning('activateGame: game %s not among announced, can not activate' % game )


    def getAnnouncedGames (self):
        return self.announcedGames


    def getActiveGames (self):
        return self.activeGames
