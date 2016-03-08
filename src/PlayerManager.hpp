#ifndef PLAYER_MANAGER_HPP
#define PLAYER_MANAGER_HPP

#include <mutex>
#include <set>

#include "Player.hpp"
#include "Packet.hpp"

/**
 * TODO: make the players a map.
 */
class PlayerManager {

public:

    static PlayerManager &instance ();

    bool isNameTaken (const std::string &name);

    void addPlayer (const SharedPlayer &player);

    void removePlayer (const SharedPlayer &player);

    /**
     * Returns the player with the given id or a null shared reference if not found.
     */
    SharedPlayer getPlayer (unsigned int playerId);

    size_t getPlayerCount ();

    /**
     * Sends the given packet to all players.
     */
    bool broadcastPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);


private:

    /**
     * Hidden constructor.
     */
    PlayerManager () {
    }

    std::mutex m_mutex;

    // all active players
    std::set<SharedPlayer> m_players;
};


#endif //IMPERIUM_SERVER_GAMEMANAGER_HPP
