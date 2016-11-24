#! /usr/bin/python

from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint
import logging
import getopt
import sys
import os
import os.path

from client_factory import ClientFactory
from auth_manager   import AuthManager
import game_id_sequence

def usage ():
    print 'usage: %s --workingdir=path --chroot={yes,no} --port=tcpPort'
    sys.exit(2)


def main ():
    tcpPort = 0
    chroot = False
    workingDir = None

    try:
        opts, args = getopt.getopt( sys.argv[1:], "w:c:p:", ["workingdir=", "chroot=", "port="])
    except getopt.GetoptError:
        usage()

    try:
        for opt, arg in opts:
             if opt in ("-w", "--workingdir"):
                workingDir = arg

             elif opt in ("-c", "--chroot"):
                 chroot = arg in ('yes', 'true', '1')

             elif opt in ("-p", "--port"):
                 tcpPort = int(arg)
    except:
        usage()

    if tcpPort < 0 or tcpPort > 65535 or not os.path.exists( workingDir ):
        usage()

    # chroot or change directory
    if workingDir != None:
        if chroot:
            try:
                os.chroot( workingDir )
            except OSError:
                print "Failed to chroot to %s, not running as root?" % workingDir
        else:
            os.chdir( workingDir )

    logging.basicConfig( format='%(asctime)s %(name)s %(levelname)s %(message)s', level=logging.DEBUG )
    logging.info( "starting Imperium server on port %d", tcpPort )

    # set up the game id sequence
    game_id_sequence.loadSequence()

    authManager = AuthManager()

    endpoint = TCP4ServerEndpoint( reactor, tcpPort )
    endpoint.listen( ClientFactory( authManager, reactor ) )

    # run the main app
    reactor.run()


if __name__ == "__main__":
    main()