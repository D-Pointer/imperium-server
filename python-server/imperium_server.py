from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint

from client_factory import ClientFactory
from auth_manager   import AuthManager

def main ():
    print "starting Imperium server"

    authManager = AuthManager()

    endpoint = TCP4ServerEndpoint( reactor, 11000 )
    endpoint.listen( ClientFactory( authManager ) )

    # run the main app
    reactor.run()

if __name__ == "__main__":
    main()