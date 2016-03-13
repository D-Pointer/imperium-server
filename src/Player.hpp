
#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <memory>
#include <boost/asio.hpp>

#include "PlayerState.hpp"
#include "Game.hpp"
#include "Packet.hpp"
#include "Statistics.hpp"

class Player {

public:

    Player (boost::asio::ip::tcp::socket &tcpSocket, boost::asio::ip::udp::socket &udpSocket);

    ~Player ();

    /**
     * Returns the TCP socket connected to the player.
     */
    boost::asio::ip::tcp::socket &getTcpSocket () {
        return m_tcpSocket;
    }

    /**
     * Returns the UDP socket connected to the player.
     */
    boost::asio::ip::udp::socket &getUdpSocket () {
        return m_udpSocket;
    }

    /**
     * Returns the player unique id.
     */
    unsigned int getId () const {
        return m_id;
    }

    const std::string & getName () const {
        return m_name;
    }

    void setName (const std::string & name) {
        m_name = name;
    }

    const SharedGame & getGame () const {
        return m_game;
    }

    void setGame (const SharedGame & game) {
        m_game = game;
    }

    void clearGame () {
        m_game.reset();
    }

    Statistics & getStatistics () {
        return m_statistics;
    }


    bool sendPacket (Packet::PacketType packetType);

    bool sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);

    std::string toString () const;


private:

    bool sendHeader (Packet::PacketType packetType, unsigned short length);

    unsigned int m_id;
    static unsigned int m_nextId;

    boost::asio::ip::tcp::socket &m_tcpSocket;
    boost::asio::ip::udp::socket &m_udpSocket;

    // the player name
    std::string m_name;

    // possible game the player is in or has announced
    SharedGame m_game;

    // all statistics for this player
    Statistics m_statistics;
};

typedef std::shared_ptr<Player> SharedPlayer;

#endif //IMPERIUM_SERVER_PLAYER_HPP
