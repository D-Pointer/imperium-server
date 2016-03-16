#include <boost/filesystem.hpp>

#include "GameManager.hpp"
#include "Log.hpp"
#include "Player.hpp"
#include "PlayerManager.hpp"

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
    logDebug << "GameManager::addGame: added game: " << game->toString() << ", games now: " << m_games.size();

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

    time_t created = game->getCreationTime();
    time_t started = game->getStartTime();
    time_t ended = game->getEndTime();

    logDebug << "GameManager::removeGame: removed game: " << game->toString() << ", games now: " << m_games.size();
    logDebug << "GameManager::removeGame: game created: " << created << ", started: " << started << ", ended: " << ended;

    if ( ended != 0 ) {
        logDebug << "GameManager::removeGame: game duration: " << ( ended - started ) << " seconds";
    }

    for ( int index = 0; index < 2; ++index ) {
        Statistics &stats = game->getStatistics( index );
        logDebug << "GameManager::removeGame: player " << index << ": UDP packet last received: " << stats.m_lastReceivedUdp;
        logDebug << "GameManager::removeGame: player " << index << ": UDP packet last sent: " << stats.m_lastSentUdp;
        logDebug << "GameManager::removeGame: player " << index << ": UDP packets sent: " << stats.m_packetsSentUdp;
        logDebug << "GameManager::removeGame: player " << index << ": UDP packets received: " << stats.m_packetsReceivedUdp;
        logDebug << "GameManager::removeGame: player " << index << ": UDP bytes sent: " << stats.m_bytesSentUdp;
        logDebug << "GameManager::removeGame: player " << index << ": UDP bytes received: " << stats.m_bytesReceivedUdp;
    }

    char buffer[50];
    time_t now = time( 0 );
    strftime( buffer, 50, "%Y-%m-%d", localtime( &now ));
    boost::filesystem::path archivePath( "games" );
    archivePath /= buffer;

    if ( !boost::filesystem::exists( archivePath )) {
        try {
            boost::filesystem::create_directories( archivePath );
        }
        catch (const boost::filesystem::filesystem_error &ex) {
            logError << "GameManager::removeGame: failed to create directory for saved games: " << archivePath.string() << ", reason: " << ex.what();
            return;
        }
    }

    // the filename is just the game id
    std::stringstream ss;
    ss << game->getGameId() << ".txt";
    archivePath /= ss.str();

    boost::filesystem::ofstream out( archivePath, std::ios_base::out );

    // players
    SharedPlayer player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
    SharedPlayer player2 = PlayerManager::instance().getPlayer( game->getPlayerId2());

    out << "scenario " << game->getScenariodId() << std::endl

    // times
    << "created " << game->getCreationTime() << std::endl
    << "started " << game->getStartTime() << std::endl
    << "ended " << game->getEndTime() << std::endl
    << "player1 " << ( player1 ? player1->getName() : "unnamed" ) << std::endl
    << "player2 " << ( player2 ? player2->getName() : "unnamed" ) << std::endl;

    // stats
    for ( int index = 0; index < 2; ++index ) {
        Statistics &stats = game->getStatistics( index );

        out << "player" << ( index + 1 )
        << " " << stats.m_lastReceivedUdp
        << " " << stats.m_lastSentUdp
        << " " << stats.m_packetsSentUdp
        << " " << stats.m_packetsReceivedUdp
        << " " << stats.m_bytesSentUdp
        << " " << stats.m_bytesReceivedUdp << std::endl;
    }

    out.close();
}


std::set<SharedGame> GameManager::getAllGames () {
    std::lock_guard<std::mutex> lock( m_mutex );

    std::set<SharedGame> result;
    result.insert( m_games.begin(), m_games.end());
    return result;
}


GameManager::GameManager () : m_sequenceFile( "games.seq" ) {
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
