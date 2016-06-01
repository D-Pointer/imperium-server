#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include <iostream>

#include "ManagementServer.hpp"
#include "Log.hpp"
#include "GlobalStatistics.hpp"

using boost::asio::ip::tcp;


ManagementServer::ManagementServer (boost::asio::io_service &io_service, const std::string & ip, short port)
        : m_io_service( io_service ), m_acceptor( io_service, tcp::endpoint(boost::asio::ip::address::from_string(ip), port )) {

    ManagementClient *client = new ManagementClient( m_io_service );

    // reuse addresses
    m_acceptor.set_option( boost::asio::ip::tcp::acceptor::reuse_address( true ));

    m_acceptor.async_accept( client->getTcpSocket(),
                             boost::bind( &ManagementServer::handleAccept, this, client, boost::asio::placeholders::error ));
}


void ManagementServer::handleAccept (ManagementClient *client, const boost::system::error_code &error) {
    logInfo << "ManagementServer::handleAccept: new client";

    if ( !error ) {
        // start and save for later
        client->start();

        // start a new session that we listen on
        client = new ManagementClient( m_io_service );
        m_acceptor.async_accept( client->getTcpSocket(),
                                 boost::bind( &ManagementServer::handleAccept, this, client, boost::asio::placeholders::error ));

        // one more manager
        GlobalStatistics::instance().m_totalConnectedManagers++;
        GlobalStatistics::instance().m_lastConnectedManager = time( 0 );
    }
    else {
        logError << "ManagementServer::handleAccept: got error: " << error.message() << ", deleting handler";
        delete client;
    }
}

