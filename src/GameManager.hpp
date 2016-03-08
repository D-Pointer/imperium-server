#ifndef IMPERIUM_SERVER_GAMEMANAGER_HPP
#define IMPERIUM_SERVER_GAMEMANAGER_HPP

#include <mutex>
#include <set>

#include "Game.hpp"

class GameManager {

public:

    static GameManager & instance ();

    void addGame (const SharedGame & game);

    void removeGame (const SharedGame & game);

    /**
     * Returns a copy of the set of all games.
     */
    std::set<SharedGame> getAllGames ();


private:

    /**
     * Hidden constructor.
     */
    GameManager () {

    }

    std::mutex m_mutex;

    // all active games
    std::set<SharedGame> m_games;
};


#endif 