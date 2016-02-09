
#include <iostream>

#include "Game.hpp"

unsigned int Game::m_nextId = 0;

Game::Game (unsigned short announcedId) : m_id( m_nextId++), m_announcedId(announcedId) {
    std::cout << "Game::Game: created game: " << m_id << " for announced game: " << m_announcedId << std::endl;
}


unsigned int Game::getId () const {
    return m_id;
}


unsigned int Game::getAnnouncedId () const {
    return m_announcedId;
}
