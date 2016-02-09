#! /usr/bin/env python

import sys
import asyncore
import logging
import socket

class UdpServer(asyncore.dispatcher):

    def __init__(self, host, port):
        asyncore.dispatcher.__init__(self)
        self.create_socket(socket.AF_INET, getSocket.SOCK_DGRAM)
        self.set_reuse_addr()
        self.bind(('', port))
        print "server started"

    def handle_connect(self):
        print "handle_connect"


    def handle_read(self):
        print "handle_read"
        data, addr = self.recvfrom(2048)
        print "handle_read: from: %s, data: %s" % ( str(addr), data )

    def handle_write(self):
        pass


if __name__ == '__main__':
    if len( sys.argv ) != 3:
        print 'Missing arguments, usage %s IP port' % sys.argv[0]
        sys.exit( 1 )

    ip = sys.argv[ 1 ]
    port = int ( sys.argv[2] )
    server = UdpServer( ip, port )

    try:
        print 'starting main loop'
        asyncore.loop()
    except KeyboardInterrupt:
        print 'Interrupted, exiting'
        pass

