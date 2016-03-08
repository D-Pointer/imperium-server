
#include <iostream>

#include "GameManager.hpp"

GameManager & GameManager::instance () {
    static GameManager instance;
    return instance;
}


void GameManager::addGame (const SharedGame & game) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_games.insert( game );
    std::cout << "GameManager::addGame: added game: " << game->getGameId() << ", games now: " << m_games.size() << std::endl;
}


void GameManager::removeGame (const SharedGame & game) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_games.erase( game );
    std::cout << "GameManager::removeGame: removed game: " << game->getGameId() << ", games now: " << m_games.size() << std::endl;
}


std::set<SharedGame> GameManager::getAllGames () {
    std::lock_guard<std::mutex> lock( m_mutex );

    std::set<SharedGame> result;
    result.insert( m_games.begin(), m_games.end() );
    return result;
}
