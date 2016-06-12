#include <iostream>
#include <mutex>

#include "PlayerManager.hpp"
#include "Log.hpp"

PlayerManager &PlayerManager::instance () {
    static PlayerManager instance;
    return instance;
}


bool PlayerManager::isNameTaken (const std::string &name) {
    std::lock_guard<std::mutex> lock( m_mutex );

    for ( auto player : m_players ) {
        if ( player.second->getName() == name ) {
            // name has been taken
            return true;
        }
    }

    // name is unique
    return false;
}


void PlayerManager::addPlayer (PlayerHandler * player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_players[ player->getId() ] = player;
    logDebug << "PlayerManager::addPlayer: added player: " << player->toString() << ", players now: " << m_players.size();
}


void PlayerManager::removePlayer (PlayerHandler *player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_players.erase( player->getId() );
    logDebug << "PlayerManager::removePlayer: removed player: " << player->toString() << ", players now: " << m_players.size();
}


size_t PlayerManager::getPlayerCount ()  {
    std::lock_guard<std::mutex> lock( m_mutex );

    return m_players.size();
}


PlayerHandler * PlayerManager::getPlayer (unsigned int playerId)  {
    std::lock_guard<std::mutex> lock( m_mutex );
    PlayerHandler * player;

    for ( auto playerData : m_players ) {
        player = playerData.second;
        if ( player->getId() == playerId ) {
            return player;
        }
    }

    return 0;
}


bool PlayerManager::broadcastPacket (Packet::TcpPacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    std::lock_guard<std::mutex> lock( m_mutex );

    logDebug << "PlayerManager::broadcastPacket: broadcasting packet: " << Packet::getPacketName(packetType) << " to " << m_players.size() << " players";

    for ( auto player : m_players ) {
        player.second->sendPacket( packetType, buffers );
    }

    // broadcasted ok
    return true;
}
