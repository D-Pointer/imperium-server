#ifndef PLAYER_MANAGER_HPP
#define PLAYER_MANAGER_HPP

#include <mutex>
#include <set>

#include "Player.hpp"
#include "Packet.hpp"

class PlayerManager {

public:

    static PlayerManager & instance ();

    bool isNameTaken (const std::string & name);

    void addPlayer (const SharedPlayer &player);

    void removePlayer (const SharedPlayer &player);

    size_t getPlayerCount () const;

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
