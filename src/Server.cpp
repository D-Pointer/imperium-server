#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include <iostream>

#include "Server.hpp"
#include "PlayerManager.hpp"

using boost::asio::ip::tcp;

Server::Server (boost::asio::io_service &io_service, short port)
        : m_io_service( io_service ), m_acceptor( io_service, tcp::endpoint( tcp::v4(), port )) {
    PlayerHandler *session = new PlayerHandler( m_io_service );
    session->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );

    // reuse addresses
    m_acceptor.set_option( boost::asio::ip::tcp::acceptor::reuse_address( true ));

    m_acceptor.async_accept( session->getSocket(),
                             boost::bind( &Server::handleAccept, this, session, boost::asio::placeholders::error ));
}


void Server::handleAccept (PlayerHandler *playerHandler, const boost::system::error_code &error) {
    std::cout << "Server::handleAccept: new client" << std::endl;

    if ( !error ) {
        // start and save for later
        playerHandler->start();

        m_playerHandlers.insert( playerHandler );
        std::cout << "Server::handleAccept: player handlers now: " << m_playerHandlers.size() << std::endl;

        // start a new session that we listen on
        playerHandler = new PlayerHandler( m_io_service );
        playerHandler->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );
        m_acceptor.async_accept( playerHandler->getSocket(),
                                 boost::bind( &Server::handleAccept, this, playerHandler, boost::asio::placeholders::error ));
    }
    else {
        std::cout << "Server::handleAccept: got error: " << error.message() << ", deleting handler" << std::endl;
        delete playerHandler;
    }
}


void Server::sessionTerminated (PlayerHandler * player) {
    std::cout << "Server::sessionTerminated: player: " << player->toString() << " terminated" << std::endl;
    m_playerHandlers.erase( player );
    std::cout << "Server::sessionTerminated: players left: " << PlayerManager::instance().getPlayerCount() << std::endl;

    delete player;
}
