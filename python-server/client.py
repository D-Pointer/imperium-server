from twisted.protocols.basic import Int16StringReceiver


class Client(Int16StringReceiver):

    nextId = 0

    def __init__ (self, clients):
        self.clients = clients
        self.id = Client.nextId
        Client.nextId += 1


    def connectionMade(self):
        self.clients[ self.id ] = self
        print "connectionMade: clients now: %d" % len(self.clients)

        # self.factory was set by the factory's default buildProtocol:
        self.transport.write( 'Hello world!\r\n')
        #self.transport.loseConnection()


    def connectionLost(self, reason):
        if self.id in self.clients:
            del self.clients[ self.id ]

        print "connectionLost: clients left: %d" % len(self.clients)


    def stringReceived(self, string):
        print "stringReceived: received %d bytes" % len(string)