
#include <sstream>

#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>
#include <boost/algorithm/string/trim.hpp>

#include "ManagementClient.hpp"
#include "GameManager.hpp"
#include "PlayerManager.hpp"
#include "Log.hpp"
#include "GlobalStatistics.hpp"
#include "Version.hpp"

using boost::asio::ip::udp;

ManagementClient::ManagementClient (boost::asio::io_service &io_service) : m_tcpSocket( io_service ) {

}


ManagementClient::~ManagementClient () {
    logDebug << "ManagementClient::~ManagementClient";
    boost::system::error_code error;
    m_tcpSocket.close( error );
}


void ManagementClient::start () {
    // read the first request
    boost::asio::async_read_until( m_tcpSocket, m_buffer, "\n",
                                   boost::bind( &ManagementClient::handleRequest, this,
                                                boost::asio::placeholders::error,
                                                boost::asio::placeholders::bytes_transferred ));
}


std::string ManagementClient::toString () const {
    std::stringstream ss;
    ss << "[ManagementClient]";
    return ss.str();
}


void ManagementClient::handleRequest (const boost::system::error_code &error, std::size_t bytesTransferred) {
    // some form of error?
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << "ManagementClient::handleRequest: connection closed";
            return;
        }

        logError << "ManagementClient::handleRequest: error reading request: " << error.message();
        boost::system::error_code tmpError;
        m_tcpSocket.close( tmpError );
        return;
    }

    // extract the request
    std::ostringstream ss;
    ss << &m_buffer;
    std::string request = ss.str();
    boost::algorithm::trim( request );

    if ( request == "status" ) {
        handleStatus();
    }
    else {
        logError << "ManagementClient::handleRequest: unknown request '" << request << "', ignoring";
    }

    // read the next request
    boost::asio::async_read_until( m_tcpSocket, m_buffer, "\n",
                                   boost::bind( &ManagementClient::handleRequest, this,
                                                boost::asio::placeholders::error,
                                                boost::asio::placeholders::bytes_transferred ));
}


void ManagementClient::handleStatus () {
    logDebug << "ManagementClient::handleStatus: sending server status";

    std::stringstream ss;

    GlobalStatistics &stats( GlobalStatistics::instance());

    ss << "{" << std::endl
    << "\"started\":" << stats.m_startTime << ',' << std::endl
    << "\"majorVersion\":" << MAJOR_VERSION << ',' << std::endl
    << "\"minorVersion\":" << MINOR_VERSION << ',' << std::endl
    << "\"extraVersion\":" << EXTRA_VERSION << ',' << std::endl
    << "\"totalConnectedPlayers\":" << stats.m_totalConnectedPlayers << ',' << std::endl
    << "\"totalConnectedManagers\":" << stats.m_totalConnectedManagers << ',' << std::endl
    << "\"lastConnectedPlayer\":" << stats.m_lastConnectedPlayer << ',' << std::endl
    << "\"lastConnectedManager\":" << stats.m_lastConnectedManager << std::endl
    << "}" << std::endl;

    // send the reply
    boost::system::error_code error;
    boost::asio::write( m_tcpSocket, boost::asio::buffer( ss.str() ), boost::asio::transfer_all(), error );

    // sent ok?
    if ( error ) {
        logError << "ManagementClient::handleStatus: error sending status to client";
    }
}
