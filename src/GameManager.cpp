
#include <iostream>

#include "GameManager.hpp"

GameManager & GameManager::instance () {
    static GameManager instance;
    return instance;
}


void GameManager::addGame (const SharedGame & game) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_games.insert( game );
    std::cout << "GameManager::addGame: added game: " << game->getId() << ", games now: " << m_games.size() << std::endl;
}
