#! /usr/bin/env python

import sys
import logging
import sys
import socket
import struct
from packet import Packet

logging.basicConfig(level=logging.DEBUG,
                    format='%(name)s: %(message)s',
                    )

if __name__ == '__main__':
    ip = sys.argv[1]
    port = int(sys.argv[2] )
    logger = logging.getLogger('client')
    logger.info('Server on %s:%d', ip, port)

    headerLength = struct.calcsize( 'hh' )

    # Connect to the server
    logger.debug('creating socket')
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    logger.debug('connecting to server')
    s.connect((ip, port))

    # info
    name = "Chakie".encode('ascii')
    length = headerLength + struct.calcsize( 'hIh' ) + len(name)
    message = struct.pack( 'hhhIh%ds' % len(name), length, Packet.INFO, 42, 1000230, len(name), name )
    logger.debug('sending %d bytes' % len(message) )
    len_sent = s.send(message)

    # announce our game
    message = struct.pack( 'hhh', headerLength + struct.calcsize( 'h' ), Packet.ANNOUNCE, 202 )
    logger.debug('sending %d bytes' % len(message) )
    len_sent = s.send(message)

    # get all games
    message = struct.pack( 'hh', headerLength, Packet.GET_GAMES )
    logger.debug('sending %d bytes' % len(message) )
    len_sent = s.send(message)

    # join game 0
    message = struct.pack( 'hhh', headerLength, Packet.JOIN, 2 )
    logger.debug('sending %d bytes' % len(message) )
    len_sent = s.send(message)

        # Receive a response
        # logger.debug('waiting for response')
        # response = s.recv(len_sent)
        # (v1, v2) = struct.unpack( 'hh', response )
        # logger.debug('response from server: "%d %d"', v1, v2)

    # Clean up
    logger.debug('closing socket')
    s.close()
    logger.debug('done')
