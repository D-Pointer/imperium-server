from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint

from client_factory import ClientFactory


def main ():
    print "starting Imperium server"

    endpoint = TCP4ServerEndpoint( reactor, 11000 )
    endpoint.listen(ClientFactory())
    reactor.run()

if __name__ == "__main__":
    main()