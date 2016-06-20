#ifndef PLAYER_MANAGER_HPP
#define PLAYER_MANAGER_HPP

#include <map>

#include "PlayerHandler.hpp"
#include "Packet.hpp"

/**
 *
 */
class PlayerManager {

public:

    static PlayerManager &instance ();

    bool isNameTaken (const std::string &name);

    void addPlayer (PlayerHandler *player);

    void removePlayer (PlayerHandler * player);

    /**
     * Returns the player with the given id or a null shared reference if not found.
     */
    PlayerHandler * getPlayer (unsigned int playerId);

    size_t getPlayerCount ();

    /**
     * Sends the given packet to all players.
     */
    bool broadcastPacket (Packet::TcpPacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);


private:

    /**
     * Hidden constructor.
     */
    PlayerManager () {
    }

    std::mutex m_mutex;

    // all active players
    std::map<unsigned int, PlayerHandler *> m_players;
};


#endif

