
class Game:

    nextId = 0

    def __init__ (self, scenarioId, player1, player2):
        self.scenarioId = scenarioId
        self.player1 = player1
        self.player2 = player2

        self.gameId = Game.nextId
        Game.nextId += 1
        