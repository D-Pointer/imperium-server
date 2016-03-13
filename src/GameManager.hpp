#ifndef IMPERIUM_SERVER_GAMEMANAGER_HPP
#define IMPERIUM_SERVER_GAMEMANAGER_HPP

#include <mutex>
#include <set>

#include <boost/filesystem/path.hpp>

#include "Game.hpp"

class GameManager {

public:

    static GameManager & instance ();

    SharedGame getGame (unsigned int gameId);

    SharedGame createGame (unsigned short scenarioId, unsigned int playerId);

    void removeGame (const SharedGame & game);

    /**
     * Returns a copy of the set of all games.
     */
    std::set<SharedGame> getAllGames ();


private:

    /**
     * Hidden constructor.
     */
    GameManager ();

    std::mutex m_mutex;

    // all active games
    std::set<SharedGame> m_games;

    // next available game id
    unsigned int m_nextId;

    // path to the sequence file
    boost::filesystem::path m_sequenceFile;
};


#endif 
