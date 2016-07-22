
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
    else if ( request == "quit" ) {
        handleQuit();
        return;
    }
    else if ( request == "games" ) {
        handleGames();
    }
    else if ( request == "players" ) {
        handlePlayers();
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
       << "\"lastConnectedManager\":" << stats.m_lastConnectedManager << ',' << std::endl
       << "\"activePlayers\":" << PlayerManager::instance().getPlayerCount() << ',' << std::endl
       << "\"disconnectedPlayers\":" << PlayerManager::instance().getOldStatisticsCount() << ',' << std::endl
       << "\"activeGames\":" << GameManager::instance().getGameCount() << std::endl
       << "}" << std::endl;

    // send the reply
    sendResponse( ss.str());
}


void ManagementClient::handleGames () {
    std::stringstream ss;

    std::set<SharedGame> games = GameManager::instance().getAllGames();

    ss << "{" << std::endl
       << "\"games\": [" << std::endl;

    bool first = true;
    for ( auto game : games ) {
        ss << ( first ? "{" : ",{" ) << std::endl
           << "\"id\":" << game->getGameId() << ',' << std::endl
           << "\"scenarioId\":" << game->getScenarioId() << ',' << std::endl
           << "\"playerId1\":" << game->getPlayerId1() << ',' << std::endl
           << "\"playerId2\":" << game->getPlayerId2() << ',' << std::endl
           << "\"playerName1\":\"" << game->getPlayerName1() << "\"," << std::endl
           << "\"playerName2\":\"" << game->getPlayerName2() << "\"," << std::endl
           << "\"created\":" << game->getCreationTime() << ',' << std::endl
           << "\"started\":" << game->getStartTime() << ',' << std::endl
           << "\"ended\":" << game->getEndTime() << std::endl
           << "}" << std::endl;

        first = false;
    }

    ss << "] }" << std::endl;

    // send the reply
    sendResponse( ss.str());
}


void ManagementClient::handlePlayers () {
    std::stringstream ss;

    std::set<SharedPlayer> players = PlayerManager::instance().getAllPlayers();

    ss << "{" << std::endl
       << "\"players\": [" << std::endl;

    bool first = true;
    for ( auto player : players ) {
        ss << ( first ? "{" : ",{" ) << std::endl
           << "\"id\":" << player->getId() << ',' << std::endl
           << "\"name\":\"" << player->getName() << "\"," << std::endl
           << "\"connected\":" << player->getStatistics()->m_connected << ',' << std::endl
           << "\"isLoggedIn\":" << player->isLoggedIn() << ',' << std::endl
           << "\"isReadyToStart\":" << player->isReadyToStart() << ',' << std::endl;

        SharedGame game = player->getGame();
        if ( game ) {
            ss << "\"game\":{"
               << "\"id\":" << game->getGameId() << ',' << std::endl
               << "\"scenarioId\":" << game->getScenarioId() << ',' << std::endl
               << "\"playerId1\":" << game->getPlayerId1() << ',' << std::endl
               << "\"playerId2\":" << game->getPlayerId2() << ',' << std::endl
               << "\"playerName1\":\"" << game->getPlayerName1() << "\"," << std::endl
               << "\"playerName2\":\"" << game->getPlayerName2() << "\"," << std::endl
               << "\"created\":" << game->getCreationTime() << ',' << std::endl
               << "\"started\":" << game->getStartTime() << ',' << std::endl
               << "\"ended\":" << game->getEndTime() << std::endl
               << "}" << std::endl;
        }

        ss << "}" << std::endl;

        first = false;
    }

    ss << "] }" << std::endl;

    // send the reply
    sendResponse( ss.str());
}


bool ManagementClient::sendResponse (const std::string &response) {
    // send the reply
    boost::system::error_code error;
    boost::asio::write( m_tcpSocket, boost::asio::buffer( response ), boost::asio::transfer_all(), error );

    // sent ok?
    if ( error ) {
        logError << "ManagementClient::sendResponse: error sending response to client: " << error.message();
        return false;
    }

    return true;
}


void ManagementClient::handleQuit () {
    logDebug << "ManagementClient::handleQuit: closing connection";
    boost::system::error_code tmpError;
    m_tcpSocket.close( tmpError );
}
