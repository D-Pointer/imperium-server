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


void PlayerManager::cleanupIdlePlayers () {
    std::lock_guard<std::mutex> lock( m_mutex );
    //logDebug << "PlayerManager::cleanupIdlePlayers: checking " << m_players.size() << " players";

    std::set<PlayerHandler *> toStop;

    // current time
    time_t now = time( 0 );

    // max time in seconds that the players can idle. Longer TCP idle as a player can connect, announce a game and then
    // sit and wait for players
    const unsigned int maxTcpSeconds = 600;
    const unsigned int maxUdpSeconds = 10;

    for ( auto player : m_players ) {
        SharedStatistics statistics = player.second->getStatistics();

        // has the game started?
        if ( statistics->m_lastReceivedUdp != 0 ) {
            // yes, so only check UDP
            if ( now - statistics->m_lastReceivedUdp > maxUdpSeconds ) {
                toStop.insert( player.second );
                logDebug << "PlayerManager::cleanupIdlePlayers: player " << player.second->toString() << " too long idle on UDP";
            }
        }
        else {
            // not yet started, so check TCP only
            if ( now - statistics->m_lastReceivedTcp > maxTcpSeconds ) {
                toStop.insert( player.second );
                logDebug << "PlayerManager::cleanupIdlePlayers: player " << player.second->toString() << " too long idle on TCP";
            }
        }
    }

    logDebug << "PlayerManager::cleanupIdlePlayers: removing " << toStop.size() << " idle players";

    // now stop the players that have timed out
    for ( auto player : toStop ) {
        player->stop();
    }
}
