
from twisted.internet.protocol import Factory
from client import Client

class ClientFactory(Factory):
    # This will be used by the default buildProtocol to create new protocols:
    protocol = Client

    def __init__(self):
        self.clients = {}


    def buildProtocol(self, addr):
        return Client( self.clients )