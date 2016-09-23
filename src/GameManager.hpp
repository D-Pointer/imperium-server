#ifndef GAME_MANAGER_HPP
#define GAME_MANAGER_HPP

#include <mutex>
#include <set>

#include <boost/filesystem/path.hpp>

#include "Game.hpp"

class GameManager {

public:

    static GameManager & instance ();

    /**
     * Initializes the game manages and reads the sequence from the given filename.
     *
     * @param filename
     *
     * @return true if loaded ok and false on error.
     */
    bool initialize (const std::string & filename);

    SharedGame getGame (unsigned int gameId);

    SharedGame createGame (unsigned short scenarioId, unsigned int playerId, const std::string & playerName);

    void removeGame (const SharedGame & game);

    /**
     * Returns a copy of the set of all games.
     */
    std::set<SharedGame> getAllGames ();

    size_t getGameCount () const;


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
