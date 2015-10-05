#! /usr/bin/env python

import logging
import sys
import asyncore
import socket
import struct

from game   import Game
from packet import Packet

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(name)s: %(message)s',
                    )


announcedGames = []
clients = []

class ClientHandler(asyncore.dispatcher_with_send):

    def __init__ (self, sock):
        asyncore.dispatcher_with_send.__init__(self, sock)
        self.logger = logging.getLogger('ClientHandler')

        self.clientId = -1
        self.data = ''


    def handle_read(self):
        try:
            data = self.recv(8192)
        except socket.error:
            self.logger.debug('handle_read: failed to receive data')
            return

        if not data:
            self.logger.debug('handle_read: no data received')
            return

        self.data += data

        # length of the parsed header
        headerLength = struct.calcsize( 'hh' )

        while len( self.data ) > 0:
            self.logger.debug('handle_read: data length: %d bytes', len(self.data) )

            # can we read a header?
            if len(self.data) < headerLength:
                self.logger.debug('handle_read: can not read full header' )                
                return

            # get the packet length
            (packetLength, packetType) = struct.unpack_from( 'hh', self.data, 0 )
            self.logger.debug('handle_read: packet type: %d. length: %d bytes', packetType, packetLength )

            # can we read the rest of the packet?
            if len(self.data) < packetLength:
                self.logger.debug('handle_read: can not read full packet' )                
                return

            # handle the packet
            payloadLength = self.handlePacket( packetType, self.data[ headerLength:headerLength + packetLength ] )

            # strip off the handled packet
            self.data = self.data[ headerLength + payloadLength: ]

            # response = struct.pack( 'hh', 100, 200 )
            # self.send( response )


    def handle_close(self):
        self.logger.debug('handle_close')
        self.close()

        if not self in clients:
            self.logger.debug('handle_close: self not found among clients!')
            return

        clients.remove( self )
        self.logger.debug('handle_close: client removed, now %d clients' % len(clients) )


    def handlePacket (self, packetType, data):
        self.logger.debug('handlePacket: packet type: %d', packetType )
        self.logger.debug('handlePacket: data length: %d', len(data) )

        if packetType == Packet.INFO:
            return self.handleInfoPacket( data )
        
        elif packetType == Packet.ANNOUNCE:
            return self.handleAnnouncePacket( data )

        elif packetType == Packet.JOIN:
            return self.handleJoinPacket( data )

        elif packetType == Packet.GET_GAMES:
            return self.handleGetGamesPacket( data )

        return 0


    def handleInfoPacket (self, data):
        (self.clientId, ) = struct.unpack_from( 'h', data, 0 )
        self.logger.debug('handleInfoPacket: client joined: %d', self.clientId )
        return struct.calcsize( 'h' )


    def handleAnnouncePacket (self, data):
        (scenarioId, ) = struct.unpack_from( 'h', data, 0 )

        # create a new announced game
        game = Game( scenarioId, self, None)
        announcedGames.append( game )
        self.logger.debug('handleAnnouncePacket: announce game: %d with scenario: %d', game.gameId, game.scenarioId )
        self.logger.debug('handleAnnouncePacket: announced games now: %d', len(announcedGames) )

        return struct.calcsize( 'h' )


    def handleJoinPacket (self, data):
        (gameId, ) = struct.unpack_from( 'h', data, 0 )
        self.logger.debug('handleJoinPacket: join: %d', gameId )

        # find a game
        game = None
        for tmp in announcedGames:
            if tmp.gameId == gameId:                
                game = tmp
                break

        if not game:            
            self.logger.warning('handleJoinPacket: no game found with id: %d', gameId )
        else:
            self.logger.debug('handleJoinPacket: joining game: %d', game.gameId )      
  
        return struct.calcsize( 'h' )


    def handleGetGamesPacket (self, data):
        self.logger.debug('handleGetGamesPacket' )
        return 0


class EchoServer(asyncore.dispatcher):

    def __init__(self, host, port):
        asyncore.dispatcher.__init__(self)
        self.logger = logging.getLogger('EchoServer')
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.set_reuse_addr()
        self.bind((host, port))
        self.listen(5)


    def handle_accept(self):
        self.logger.debug('handle_accept')
        pair = self.accept()
        if pair is not None:
            sock, addr = pair
            self.logger.debug( 'handle_accept: incoming connection from %s' % repr(addr) )
            handler = ClientHandler( sock )

            clients.append( handler )
            self.logger.debug( 'handle_accept: clients now: %d' % len(clients) )


if __name__ == '__main__':
    if len( sys.argv ) != 3:
        print 'Missing arguments, usage %s IP port' % sys.argv[0]
        sys.exit( 1 )

    ip = sys.argv[ 1 ]
    port = int ( sys.argv[2] )
    server = EchoServer( ip, port )

    try:
        logging.debug('starting main loop')
        asyncore.loop()
    except KeyboardInterrupt:
        print 'Interrupted, exiting'
        pass


# class EchoRequestHandler(SocketServer.BaseRequestHandler):
    
#     def __init__(self, request, client_address, server):
#         self.logger = logging.getLogger('EchoRequestHandler')
#         self.logger.debug('__init__')
#         SocketServer.BaseRequestHandler.__init__(self, request, client_address, server)
#         return

#     def setup(self):
#         self.logger.debug('setup')
#         return SocketServer.BaseRequestHandler.setup(self)

#     def handle(self):
#         self.logger.debug('handle')

#         # Echo the back to the client
#         data = self.request.recv(1024)
#         self.logger.debug('recv()->"%s"', data)
#         self.request.send(data)
#         return

#     def finish(self):
#         self.logger.debug('finish')
#         return SocketServer.BaseRequestHandler.finish(self)


# class EchoServer(SocketServer.TCPServer):
    
#     def __init__(self, server_address, handler_class=EchoRequestHandler):
#         self.logger = logging.getLogger('EchoServer')
#         self.logger.debug('__init__')
#         SocketServer.TCPServer.__init__(self, server_address, handler_class)
#         return

#     def server_activate(self):
#         self.logger.debug('server_activate')
#         SocketServer.TCPServer.server_activate(self)
#         return

#     def serve_forever(self):
#         self.logger.debug('waiting for request')
#         self.logger.info('Handling requests, press <Ctrl-C> to quit')
#         while True:
#             self.handle_request()
#         return

#     def handle_request(self):
#         self.logger.debug('handle_request')
#         return SocketServer.TCPServer.handle_request(self)

#     def verify_request(self, request, client_address):
#         self.logger.debug('verify_request(%s, %s)', request, client_address)
#         return SocketServer.TCPServer.verify_request(self, request, client_address)

#     def process_request(self, request, client_address):
#         self.logger.debug('process_request(%s, %s)', request, client_address)
#         return SocketServer.TCPServer.process_request(self, request, client_address)

#     def server_close(self):
#         self.logger.debug('server_close')
#         return SocketServer.TCPServer.server_close(self)

#     def finish_request(self, request, client_address):
#         self.logger.debug('finish_request(%s, %s)', request, client_address)
#         return SocketServer.TCPServer.finish_request(self, request, client_address)

#     def close_request(self, request_address):
#         self.logger.debug('close_request(%s)', request_address)
#         return SocketServer.TCPServer.close_request(self, request_address)


# if __name__ == '__main__':
#     address = ('localhost', 3333) # let the kernel give us a port
#     server = EchoServer(address, EchoRequestHandler)
#     ip, port = server.server_address # find out what port we were given

#     server.serve_forever()

#     t = threading.Thread(target=server.serve_forever)
#     t.setDaemon(True) # don't hang on exit
#     t.start()
