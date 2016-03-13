#include <boost/filesystem.hpp>

#include "GameManager.hpp"
#include "Log.hpp"

GameManager &GameManager::instance () {
    static GameManager instance;
    return instance;
}


SharedGame GameManager::getGame (unsigned int gameId) {
    std::lock_guard<std::mutex> lock( m_mutex );

    for ( auto game : m_games ) {
        if ( game->getGameId() == gameId ) {
            return game;
        }
    }

    return SharedGame();
}


SharedGame GameManager::createGame (unsigned short scenarioId, unsigned int playerId) {
    std::lock_guard<std::mutex> lock( m_mutex );

    // create a new game
    SharedGame game = std::make_shared<Game>( m_nextId, scenarioId, playerId );

    m_nextId++;
    
    // save for later
    m_games.insert( game );
    logDebug<< "GameManager::addGame: added game: " << game->toString()  << ", games now: " << m_games.size();

    // save the id sequence too
    try {
        boost::filesystem::ofstream out( m_sequenceFile, std::ios_base::out );
        out << m_nextId;
    }
    catch (const boost::filesystem::filesystem_error &ex) {
        logError << "GameManager::addGame: failed to write game sequence to: " << m_sequenceFile.string() << ", reason: " << ex.what();
    }

    return game;
}


void GameManager::removeGame (const SharedGame &game) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_games.erase( game );
    logDebug << "GameManager::removeGame: removed game: " << game->toString() << ", games now: " << m_games.size();
    logDebug << "GameManager::removeGame: game created: " << game->getCreationTime() << ", started: " << game->getStartTime() << ", ended: " <<
    game->getEndTime();
}


std::set<SharedGame> GameManager::getAllGames () {
    std::lock_guard<std::mutex> lock( m_mutex );

    std::set<SharedGame> result;
    result.insert( m_games.begin(), m_games.end());
    return result;
}


GameManager::GameManager () : m_sequenceFile("games.seq") {
    try {
        if ( boost::filesystem::exists( m_sequenceFile )) {
            boost::filesystem::ifstream in( m_sequenceFile, std::ios_base::in );
            in >> m_nextId;
        }
        else {
            m_nextId = 0;
        }
    }
    catch (const boost::filesystem::filesystem_error &ex) {
        logError << "GameManager::GameManager: failed to read game sequence from: " << m_sequenceFile.string() << ", reason: " << ex.what();
    }

    logDebug << "GameManager::GameManager: game sequence starts from: " << m_nextId;
}
