
#include <sstream>

#include "Game.hpp"
#include "Player.hpp"
#include "Log.hpp"

Game::Game (unsigned int id, unsigned short scenarioId, unsigned int playerId, const std::string & playerName1)
        : m_id( id ), m_scenarioId( scenarioId ), m_playerId1( playerId ), m_playerId2( 0 ), m_playerName1(playerName1), m_playerName2("unknown"),
          m_started( false ), m_startTime( 0 ), m_endTime( 0 ) {
    logDebug << "Game::Game: created game: " << m_id << " for announced game: " << m_scenarioId << " by player: " << playerId;
    m_creationTime = time( 0 );
}


Game::~Game () {
    logDebug << "Game::~Game";
    m_udpHandler.reset();
}


bool Game::hasStarted () const {
    return m_started;
}


unsigned int Game::getGameId () const {
    return m_id;
}


unsigned short Game::getScenarioId () const {
    return m_scenarioId;
}


unsigned int Game::getPlayerId1 () const {
    return m_playerId1;
}


unsigned int Game::getPlayerId2 () const {
    return m_playerId2;
}


const std::string & Game::getPlayerName1 () const {
    return m_playerName1;
}


const std::string & Game::getPlayerName2 () const {
    return m_playerName2;
}


unsigned int Game::getPeerId (unsigned int playerId) const {
    if ( playerId == m_playerId1 ) {
        return m_playerId2;
    }
    else if ( playerId == m_playerId2 ) {
        return m_playerId1;
    }

    logError << "Game::getPeerId2: trying to get peer id for a game that has not started: " << toString();
    return 0;
}


void Game::setPlayer2Data (unsigned int playerId2, const std::string & playerName2) {
    m_playerId2 = playerId2;
    m_playerName2 = playerName2;
}


void Game::setStatistics (unsigned int playerId, const SharedStatistics & statistics) {
    m_statistics[ playerId ] = statistics;
}


void Game::endGame () {
    if ( m_endTime == 0 ) {
        m_endTime = time( 0 );
    }

    if ( m_udpHandler ) {
        m_udpHandler->stop();
        m_udpHandler.reset();
    }
}


time_t Game::getCreationTime () const {
    return m_creationTime;
}


time_t Game::getStartTime () const {
    return m_startTime;
}


time_t Game::getEndTime () const {
    return m_endTime;
}


SharedStatistics Game::getStatistics (unsigned int player) {
    return m_statistics[player];
}


void Game::setUdpHandler (const SharedUdpHandler &udpHandler) {
    m_udpHandler = udpHandler;
    m_started = true;
    m_startTime = time( 0 );
}


const SharedUdpHandler &Game::getUdpHandler () const {
    return m_udpHandler;
}


std::string Game::toString () const {
    std::stringstream ss;
    ss << "[Game " << m_id << " player: " << m_playerId1 << " scenario: " << m_scenarioId << ']';
    return ss.str();
}
