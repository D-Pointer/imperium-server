
#ifndef GAME_HPP
#define GAME_HPP

#include <memory>
#include <string>
#include <ctime>

#include "Statistics.hpp"
#include "UdpHandler.hpp"

class Game {

public:

    Game (unsigned int id, unsigned short scenarioId, unsigned int playerId);

    ~Game ();

    bool hasStarted () const;

    unsigned int getGameId () const;

    unsigned short getScenarioId () const;

    unsigned int getPlayerId1 () const;
    unsigned int getPlayerId2 () const;

    /**
     * Returns the id of the peer player for the given @p playerId. This only works if the game has started.
     *
     * @param playerId the player whose peer is wanted.
     *
     * @return the peer id or 0 if the player is not in the game or the game has not started.
     */
    unsigned int getPeerId (unsigned int playerId) const;

    void setPlayerId2 (unsigned int playerId2);

    void setStatistics (unsigned int playerId, const SharedStatistics & statistics);

    void endGame ();

    time_t getCreationTime () const;
    time_t getStartTime () const;
    time_t getEndTime () const;

    SharedStatistics getStatistics (unsigned int player);

    /**
     * Sets the UDP handler that will handle all UDP traffic between the players. Setting this also marks the game
     * as started and records the start time.
     *
     * @param udpHandler the UDP handler for handling all UDP traffic.
     */
    void setUdpHandler (const SharedUdpHandler & udpHandler);
    const SharedUdpHandler & getUdpHandler () const;

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

    // all statistics for both players
    SharedStatistics m_statistics[2];

    // UDP handler
    SharedUdpHandler m_udpHandler;
};

typedef std::shared_ptr<Game> SharedGame;

#endif //IMPERIUM_SERVER_GAME_HPP
