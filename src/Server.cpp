#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include <iostream>

#include "Server.hpp"
#include "PlayerManager.hpp"
#include "Log.hpp"

using boost::asio::ip::tcp;


unsigned short Server::m_nextUdpPort = 12000;

Server::Server (boost::asio::io_service &io_service, const std::string & ip, short port)
        : m_io_service( io_service ), m_acceptor( io_service, tcp::endpoint(boost::asio::ip::address::from_string(ip), port )) {

    // the UDP port that this player will use
    unsigned short udpPort = m_nextUdpPort++;

    PlayerHandler *session = new PlayerHandler( m_io_service, udpPort );
    session->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );
    // reuse addresses

    m_acceptor.set_option( boost::asio::ip::tcp::acceptor::reuse_address( true ));

    m_acceptor.async_accept( session->getTcpSocket(),
                             boost::bind( &Server::handleAccept, this, session, boost::asio::placeholders::error ));
}


void Server::handleAccept (PlayerHandler *playerHandler, const boost::system::error_code &error) {
    logInfo << "Server::handleAccept: new client";

    if ( !error ) {
        // start and save for later
        playerHandler->start();

        m_playerHandlers.insert( playerHandler );
        logDebug << "Server::handleAccept: player handlers now: " << m_playerHandlers.size();

        // the UDP port that this player will use
        unsigned short udpPort = m_nextUdpPort++;

        // start a new session that we listen on
        playerHandler = new PlayerHandler( m_io_service, udpPort );
        playerHandler->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );
        m_acceptor.async_accept( playerHandler->getTcpSocket(),
                                 boost::bind( &Server::handleAccept, this, playerHandler, boost::asio::placeholders::error ));
    }
    else {
        logError << "Server::handleAccept: got error: " << error.message() << ", deleting handler";
        delete playerHandler;
    }
}


void Server::sessionTerminated (PlayerHandler * player) {
    logInfo << "Server::sessionTerminated: player: " << player->toString() << " terminated";
    m_playerHandlers.erase( player );
    logDebug << "Server::sessionTerminated: players handlers left: " << m_playerHandlers.size();

    delete player;
}
