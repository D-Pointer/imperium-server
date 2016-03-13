
#ifndef GAME_HPP
#define GAME_HPP

#include <memory>
#include <string>
#include <ctime>

class Game {

public:

    Game (unsigned int id, unsigned short scenarioId, unsigned int playerId);

    ~Game ();

    bool hasStarted () const;

    unsigned int getGameId () const;

    unsigned short getScenariodId () const;

    unsigned int getPlayerId1 () const;
    unsigned int getPlayerId2 () const;

    void setPlayerId2 (unsigned int playerId2);

    void endGame ();

    time_t getCreationTime () const;
    time_t getStartTime () const;
    time_t getEndTime () const;

    std::string toString () const;


private:

    unsigned int m_id;

    // the announced game id
    unsigned short m_scenarioId;

    // the announcing/owning player and the secondary player
    unsigned int m_playerId1;
    unsigned int m_playerId2;

    // has the game started?
    bool m_started;

    // when was the game created, started and finished?
    time_t m_creationTime;
    time_t m_startTime;
    time_t m_endTime;
};

typedef std::shared_ptr<Game> SharedGame;

#endif //IMPERIUM_SERVER_GAME_HPP
