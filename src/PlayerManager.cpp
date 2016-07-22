#include <iostream>
#include <mutex>

#include "PlayerManager.hpp"
#include "Log.hpp"
#include "Definitions.hpp"

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


void PlayerManager::addPlayer (const SharedPlayer &player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    m_players[player->getId()] = player;
    logDebug << "PlayerManager::addPlayer: added player: " << player->getId() << ", players now: " << m_players.size();
}


void PlayerManager::removePlayer (const SharedPlayer &player) {
    std::lock_guard<std::mutex> lock( m_mutex );

    // save the stats
    m_disconnectedPlayers.push_back( player->getStatistics());
    while ( m_disconnectedPlayers.size() > playerStatisticsCount ) {
        m_disconnectedPlayers.pop_front();
    }

    m_players.erase( player->getId());
    logDebug << "PlayerManager::removePlayer: removed player: " << player->getId() << ", players now: " << m_players.size() << ", old stats now: " << m_disconnectedPlayers.size();
}


size_t PlayerManager::getPlayerCount () {
    std::lock_guard<std::mutex> lock( m_mutex );
    return m_players.size();
}


std::set<SharedPlayer> PlayerManager::getAllPlayers () {
    std::lock_guard<std::mutex> lock( m_mutex );

    std::set<SharedPlayer> result;
    std::transform( m_players.begin(), m_players.end(), std::inserter( result, result.begin()),
                    [] (const std::pair<unsigned int, SharedPlayer> &value) {
                        return value.second;
                    } );
    return result;
}


size_t PlayerManager::getOldStatisticsCount () {
    std::lock_guard<std::mutex> lock( m_mutex );
    return m_disconnectedPlayers.size();
}


std::list<SharedStatistics> PlayerManager::getAllOldStatistics () {
    std::lock_guard<std::mutex> lock( m_mutex );

    return std::list<SharedStatistics>( m_disconnectedPlayers.begin(), m_disconnectedPlayers.end());
}


SharedPlayer PlayerManager::getPlayer (unsigned int playerId) {
    std::lock_guard<std::mutex> lock( m_mutex );
    SharedPlayer player;

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

    logDebug << "PlayerManager::broadcastPacket: broadcasting packet: " << Packet::getPacketName( packetType ) << " to " << m_players.size() << " players";

    for ( auto player : m_players ) {
        player.second->sendPacket( packetType, buffers );
    }

    // broadcasted ok
    return true;
}


void PlayerManager::cleanupIdlePlayers () {
    std::lock_guard<std::mutex> lock( m_mutex );
    //logDebug << "PlayerManager::cleanupIdlePlayers: checking " << m_players.size() << " players";

    std::set<SharedPlayer> toStop;

    // current time
    time_t now = time( 0 );

    for ( auto player : m_players ) {
        SharedStatistics statistics = player.second->getStatistics();

        // has the game started?
        if ( statistics->m_lastReceivedUdp != 0 ) {
            // yes, so only check UDP
            if ( now - statistics->m_lastReceivedUdp > maxUdpSeconds ) {
                toStop.insert( player.second );
                logDebug << "PlayerManager::cleanupIdlePlayers: player " << player.second->getId() << " too long idle on UDP";
            }
        }
        else {
            // not yet started, so check TCP only
            if ( now - statistics->m_lastReceivedTcp > maxTcpSeconds ) {
                toStop.insert( player.second );
                logDebug << "PlayerManager::cleanupIdlePlayers: player " << player.second->getId() << " too long idle on TCP";
            }
        }
    }

    if ( toStop.size() > 0 ) {
        logDebug << "PlayerManager::cleanupIdlePlayers: removing " << toStop.size() << " idle players";
    }

    // now stop the players that have timed out
    for ( auto player : toStop ) {
        player->stop();
    }
}
