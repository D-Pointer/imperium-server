from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint

from client_factory import ClientFactory
from auth_manager   import AuthManager

TCP_PORT = 11000

def main ():
    print "starting Imperium server on port %d" % TCP_PORT

    authManager = AuthManager()

    endpoint = TCP4ServerEndpoint( reactor, TCP_PORT )
    endpoint.listen( ClientFactory( authManager, reactor ) )

    # run the main app
    reactor.run()

if __name__ == "__main__":
    main()