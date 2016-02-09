import datetime


class Game:
    def __init__(self, gameId, scenarioId, player1, player2, logger):
        self.gameId = gameId
        self.scenarioId = scenarioId
        self.player1 = player1
        self.player2 = player2
        self.logger = logger

        # record the start time
        self.created = datetime.datetime.now()
        self.started = None

        # no UDP port yet
        self.udpPort = -1

        # not active yet
        self.active = False

        # no UDP server yet
        self.udpServer = None

    def start (self, udpPort):
        self.udpPort = udpPort
        self.started = datetime.datetime.now()
        self.active = True

    def cleanup(self):
        # the players no longer have games
        if self.player1 is not None:
            self.player1.game = None

        if self.player2 is not None:
            self.player2.game = None

        self.logger.info('game created: %s', self.created.isoformat(' '))

        # log extra info if the game was started
        if self.started is not None:
            self.logger.info('game started: %s', self.started.isoformat(' '))

            # game length
            length = (datetime.datetime.now() - self.started).total_seconds()
            hours, remainder = divmod(length, 3600)
            minutes, seconds = divmod(remainder, 60)
            self.logger.info('game duration: %d:%02d:%02d', hours, minutes, seconds)

        else:
            self.logger.info('game started: not started')

        # clean up UDP server
        if self.udpServer is not None:
            self.logger.info('UDP packets sent: %d, bytes: %d', self.udpServer.getPacketsSent(),
                             self.udpServer.getBytesSent())
            self.udpServer.close()
            self.udpServer = None


    def removePlayer(self, player):
        if self.player1 == player:
            self.player1 = None

        elif self.player2 == player:
            self.player2 = None

        return self.playerCount()

    def playerCount(self):
        if self.player1 and self.player2:
            return 2

        elif self.player1 or self.player2:
            return 1

        return 0

    def __str__(self):
        if self.udpPort != -1:
            return "[Game %d, port: %d, scenario: %d, players: %d]" % (
                self.gameId, self.udpPort, self.scenarioId, self.playerCount())
        else:
            return "[Game %d, scenario: %d, players: %d]" % (self.gameId, self.scenarioId, self.playerCount())
