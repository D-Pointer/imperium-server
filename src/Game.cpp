
#include <sstream>

#include "Game.hpp"
#include "PlayerHandler.hpp"
#include "Log.hpp"

Game::Game (unsigned int id, unsigned short scenarioId, unsigned int playerId)
        : m_id(id), m_scenarioId(scenarioId), m_playerId1(playerId), m_playerId2(0), m_started(false), m_startTime(0), m_endTime(0) {
    logDebug << "Game::Game: created game: " << m_id << " for announced game: " << m_scenarioId << " by player: " << playerId;
    m_creationTime = time(0);
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


unsigned short Game::getScenariodId () const {
    return m_scenarioId;
}


unsigned int Game::getPlayerId1 () const {
    return m_playerId1;
}


unsigned int Game::getPlayerId2 () const {
    return m_playerId2;
}


void Game::setPlayerId2 (unsigned int playerId2) {
    m_playerId2 = playerId2;
    m_started = true;
    m_startTime = time(0);
}


void Game::endGame () {
    if ( m_endTime == 0 ) {
        m_endTime = time( 0 );
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


Statistics & Game::getStatistics (unsigned int player) {
    return m_statistics[ player ];
}


void Game::setUdpHandler (const SharedUdpHandler & udpHandler) {
    m_udpHandler = udpHandler;
}


const SharedUdpHandler & Game::getUdpHandler () const {
    return m_udpHandler;
}


std::string Game::toString () const {
    std::stringstream ss;
    ss << "[Game " << m_id << " player: " << m_playerId1 << " scenario: " << m_scenarioId << ']';
    return ss.str();
}
