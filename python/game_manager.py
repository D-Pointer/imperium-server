
from game       import Game
from udp_server import UdpServer

class GameManager:

    nextGameId = 0

    lowUdpPort  = 30000
    highUdpPort = 40000
    nextUdpPort = lowUdpPort

    def __init__ (self, logger):
        # no games yet
        self.announcedGames = []
        self.activeGames = []

        self.logger = logger

        try:
            self.nextGameId = int( open( 'data/games.seq' ).readline() )
        except:
            self.nextGameId = 0


    def getGame (self, gameId):
        for game in self.announcedGames:
            if game.gameId == gameId:
                return game

        for game in self.activeGames:
            if game.gameId == gameId:
                return game

        return None


    def createGame (self, scenarioId, player1):
        # create the game
        game = Game( self.nextGameId, scenarioId, player1, None, self.logger)
        self.nextGameId += 1

        # save the updated game id sequence
        try:
            file = open( 'data/games.seq', 'w')
            file.write( str(self.nextGameId) )
            file.close()
        except:
            self.logger.error( 'failed to save updated game id sequence!' )

        return game


    def addGame (self, game):
        self.announcedGames.append( game )


    def removeGame (self, game):
        if game in self.announcedGames:
            self.announcedGames.remove( game )

        elif game in self.activeGames:
            self.activeGames.remove( game )

        else:
            self.logger.warning('game %s not found, can not remove' % game )


    def activateGame (self, game):
        if game in self.announcedGames:
            self.announcedGames.remove( game )
            self.activeGames.append( game )

            while True:
                port = self.nextUdpPort
                self.nextUdpPort += 1
                if self.nextUdpPort == self.highUdpPort:
                    self.nextUdpPort = self.lowUdpPort

                # verify that the port is not used by any other game
                for activeGame in self.activeGames:
                    if activeGame.udpPort == port:
                        continue

                # no game uses that port, start it
                game.start( port )

                # create the UDP server
                game.udpServer = UdpServer( game, self.logger )

                self.logger.debug( 'game %s activated, active games now %d' % ( game, len(self.activeGames) ) )
                return
        else:
            self.logger.warning('game %s not among announced, can not activate' % game )



    def getAnnouncedGames (self):
        return self.announcedGames


    def getActiveGames (self):
        return self.activeGames
