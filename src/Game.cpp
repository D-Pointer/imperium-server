
#include <iostream>
#include <sstream>

#include "Game.hpp"
#include "PlayerHandler.hpp"

unsigned int Game::m_nextId = 0;

Game::Game (unsigned short announcedId/*, SharedPlayer player1*/) : m_id( m_nextId++), m_announcedId(announcedId) { //, m_player1(player1) {
    std::cout << "Game::Game: created game: " << m_id << " for announced game: " << m_announcedId << std::endl;
}


unsigned int Game::getId () const {
    return m_id;
}


unsigned short Game::getAnnouncedId () const {
    return m_announcedId;
}


//const SharedPlayer & Game::getPlayer1 () const {
//    return m_player1;
//}
//
//
//const SharedPlayer & Game::getPlayer2 () const {
//    return m_player2;
//}



std::string Game::toString () const {
    std::stringstream ss;
    ss << "[Game " << m_id << " scenario: " << m_announcedId << ']';

//    ss << "[Game " << m_id << " player1: " << m_player1->toString();
//
//    if ( m_player2 ) {
//        ss << " player2: " << m_player2->toString();
//    }
//    ss << ']';

    return ss.str();
}
