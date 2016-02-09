import asynchat
import json
import version


class StatsHandler(asynchat.async_chat):
    handlerId = 0

    def __init__(self, sock, server, logger):
        asynchat.async_chat.__init__(self, sock)
        StatsHandler.handlerId += 1

        # save all data
        self.server = server
        self.logger = logger

        # no data yet
        self.buffer = []
        self.set_terminator("\n")

        self.logger.info('initialized stats handler')

    def collect_incoming_data(self, data):
        """Buffer the data"""
        self.buffer.append(data)

    def found_terminator(self):
        # marge the command
        command = "".join(self.buffer).strip().lower()
        self.buffer = []

        # skip empty lines
        if command == '':
            self.logger.warning('received empty command')
            return

        self.logger.debug('received command "%s"', command)

        self.handleCommand(command)

    def handleCommand(self, command):
        if command == 'quit':
            self.logger.debug('received quit, closing connection')
            self.close()

        elif command == 'players':
            self.logger.debug('received players, sending all players')
            self.sendPlayers()

        elif command == 'stats':
            self.logger.debug('received stats, sending server stats')
            self.sendStats()

    def sendPlayers(self):
        data = {}

        # this response contains players
        data['type'] = 'players'

        activePlayers = []
        for playerHandler in self.server.playerManager.getPlayers():
            player = playerHandler.player
            activePlayers.append({'name': player.name,
                            'id': player.id})

        data['activePlayers'] = activePlayers

        registeredPlayers = []
        for player in self.server.registrationManager.getPlayers():
            registeredPlayers.append({'name': player.name,
                            'id': player.id})

        data['registeredPlayers'] = registeredPlayers

        # send the player data as JSON
        self.send(json.dumps(data))
        self.send('\n')

    def sendStats(self):
        data = {}

        # this response contains stats
        data['type'] = 'stats'

        # server version
        data['version'] = version.version

        # startup time
        data['started'] = self.server.started.strftime("%Y-%m-%d %H:%M:%S")

        # player count
        data['activePlayers'] = self.server.playerManager.getPlayerCount()

        # registered player count
        data['registeredPlayers'] = self.server.registrationManager.getPlayerCount()

        # game counts
        data['announcedGames'] = len(self.server.gameManager.getAnnouncedGames())
        data['activeGames'] = len(self.server.gameManager.getActiveGames())

        # send the player data as JSON
        self.send(json.dumps(data, ensure_ascii=False))
        self.send('\n')
