
#ifndef GAME_HPP
#define GAME_HPP

#include <memory>
#include <string>

class Game {

public:

    Game (unsigned short scenarioId, unsigned int playerId);

    ~Game ();

    unsigned int getGameId () const;

    unsigned short getScenariodId () const;

    unsigned int getPlayerId () const;

    std::string toString () const;


private:

    unsigned int m_id;
    static unsigned int m_nextId;

    // the announced game id
    unsigned short m_scenarioId;

    // the announcing/owning player
    unsigned int m_playerId;
};

typedef std::shared_ptr<Game> SharedGame;

#endif //IMPERIUM_SERVER_GAME_HPP
