
import time

class Game:

    def __init__ (self, gameId, scenarioId, player1, player2):
        self.gameId = gameId
        self.scenarioId = scenarioId
        self.player1 = player1
        self.player2 = player2

        # record the start time
        self.started = time.time()

        # no UDP port yet
        self.udpPort = -1

        # not active yet
        self.active = False


    def removePlayer (self, player):
        if self.player1 == player:
            self.player1 = None
        
        elif self.player2 == player:
            self.player2 = None

        return self.playerCount()


    def playerCount (self):
        if self.player1 and self.player2:
            return 2

        elif self.player1 or self.player2:
            return 1

        return 0


    def __str__ (self):
        if self.udpPort != -1:
            return "[Game %d, port: %d, scenario: %d, players: %d]" % (self.gameId, self.udpPort, self.scenarioId, self.playerCount() )
        else:
            return "[Game %d, scenario: %d, players: %d]" % (self.gameId, self.scenarioId, self.playerCount() )
