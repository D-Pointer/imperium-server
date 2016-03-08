#include <iostream>

#include "PlayerManager.hpp"

PlayerManager &PlayerManager::instance () {
    static PlayerManager instance;
    return instance;
}


bool PlayerManager::isNameTaken (const std::string &name) {
    std::lock_guard<std::mutex> lock( m_mutex );

    for ( auto player : m_players ) {
        if ( player->getName() == name ) {
            // name has been taken
            return true;
        }
    }

    // name is unique
    return false;
}


void PlayerManager::addPlayer (const SharedPlayer &player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_players.insert( player );
    std::cout << "PlayerManager::addPlayer: added player: " << player->toString() << ", players now: " << m_players.size() << std::endl;
}


void PlayerManager::removePlayer (const SharedPlayer &player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_players.erase( player );
    std::cout << "PlayerManager::removePlayer: removed player: " << player->toString() << ", players now: " << m_players.size() << std::endl;
}


size_t PlayerManager::getPlayerCount ()  {
    std::lock_guard<std::mutex> lock( m_mutex );

    return m_players.size();
}


SharedPlayer PlayerManager::getPlayer (unsigned int playerId)  {
    std::lock_guard<std::mutex> lock( m_mutex );

    for ( auto player : m_players ) {
        if ( player->getId() == playerId ) {
            return player;
        }
    }

    return SharedPlayer();
}


bool PlayerManager::broadcastPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    std::lock_guard<std::mutex> lock( m_mutex );

    std::cout << "PlayerManager::broadcastPacket: broadcasting packet: " << packetType << " to " << m_players.size() << " players" << std::endl;

    std::for_each( std::begin( m_players ), std::end( m_players ),
                   [ = ] (SharedPlayer player) {
                       player->sendPacket( packetType, buffers );
                   } );

    // broadcasted ok
    return true;
}
