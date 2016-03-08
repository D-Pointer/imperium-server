
#include <iostream>
#include <sstream>

#include "Game.hpp"
#include "PlayerHandler.hpp"

unsigned int Game::m_nextId = 0;

Game::Game (unsigned short announcedId, unsigned int playerId) : m_id( m_nextId++), m_announcedId(announcedId), m_playerId(playerId) {
    std::cout << "Game::Game: created game: " << m_id << " for announced game: " << m_announcedId << " by player: " << playerId << std::endl;
}


Game::~Game () {
    std::cout << "Game::~Game" << std::endl;
}


unsigned int Game::getGameId () const {
    return m_id;
}


unsigned short Game::getAnnouncedId () const {
    return m_announcedId;
}


unsigned int Game::getPlayerId () const {
    return m_playerId;
}


std::string Game::toString () const {
    std::stringstream ss;
    ss << "[Game " << m_id << " player: " << m_playerId << " scenario: " << m_announcedId << ']';
    return ss.str();
}
