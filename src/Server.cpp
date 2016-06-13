#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include <iostream>

#include "Server.hpp"
#include "GlobalStatistics.hpp"
#include "Log.hpp"
#include "PlayerManager.hpp"

using boost::asio::ip::tcp;


unsigned short Server::m_nextUdpPort = 12000;
unsigned int Server::m_nextPlayerId = 1;

Server::Server (boost::asio::io_service &io_service, const std::string & ip, short port)
        : m_io_service( io_service ), m_acceptor( io_service, tcp::endpoint(boost::asio::ip::address::from_string(ip), port )) {

    // the UDP port that this player will use
    unsigned short udpPort = m_nextUdpPort++;

    PlayerHandler *session = new PlayerHandler( m_io_service, udpPort, Server::m_nextPlayerId++ );
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

        PlayerManager::instance().addPlayer( playerHandler );

        logDebug << "Server::handleAccept: player handlers now: " << PlayerManager::instance().getPlayerCount();


        // the UDP port that this player will use
        unsigned short udpPort = m_nextUdpPort++;

        // sanity check so that we don't wrap to port 0
        if ( m_nextUdpPort > 65530 ) {
            m_nextUdpPort = 12000;
        }

        // start a new session that we listen on
        playerHandler = new PlayerHandler( m_io_service, udpPort, Server::m_nextPlayerId++ );
        playerHandler->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );
        m_acceptor.async_accept( playerHandler->getTcpSocket(),
                                 boost::bind( &Server::handleAccept, this, playerHandler, boost::asio::placeholders::error ));

        // one more player
        GlobalStatistics::instance().m_totalConnectedPlayers++;
        GlobalStatistics::instance().m_lastConnectedPlayer = time( 0 );
    }
    else {
        logError << "Server::handleAccept: got error: " << error.message() << ", deleting handler";
        delete playerHandler;
    }
}


void Server::sessionTerminated (PlayerHandler * playerHandler) {
    logInfo << "Server::sessionTerminated: player: " << playerHandler->toString() << " terminated";

    PlayerManager::instance().removePlayer( playerHandler );
    logDebug << "Server::sessionTerminated: players handlers left: " << PlayerManager::instance().getPlayerCount();

    delete playerHandler;
}
