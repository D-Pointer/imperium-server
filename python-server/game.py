
import datetime

class Game:

    nextId = 0

    def __init__ (self, player1, scenarioId):
        # we have the first player now
        self.player1 = player1
        self.player2 = None
        self.scenarioId = scenarioId

        self.id = Game.nextId
        Game.nextId += 1

        # the game was announced now
        self.created = datetime.datetime.now()
        self.started = None
        self.ended = None


    def hasStarted (self):
        return self.player2 != None


    def getOpponent (self, player):
        if player == self.player1:
            return self.player2

        return self.player1


    def endGame (self):
        self.ended = datetime.datetime.now()