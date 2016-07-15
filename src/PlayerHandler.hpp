#ifndef PLAYER_HANDLER_HPP
#define PLAYER_HANDLER_HPP

#include <vector>
#include <memory>
#include <boost/asio.hpp>
#include <boost/signals2.hpp>
#include <boost/array.hpp>

#include "Packet.hpp"
#include "Game.hpp"

/**
 *
 **/
class PlayerHandler : public std::enable_shared_from_this<PlayerHandler> {
public:

    PlayerHandler (boost::asio::io_service &io_service, unsigned short udpPort, unsigned int playerId);

    virtual ~PlayerHandler ();

    /**
     * Signal emitted when the session terminates.
     */
    boost::signals2::signal<void (PlayerHandler *)> terminated;

    /**
     * Starts the session. Reads the first header.
     **/
    void start ();

    void stop ();

    /**
     * Returns the player unique id.
     */
    unsigned int getId () const {
        return m_id;
    }

    const std::string & getName () const {
        return m_name;
    }

    const SharedStatistics & getStatistics () const {
        return m_statistics;
    }

    bool sendPacket (Packet::TcpPacketType packetType);

    bool sendPacket (Packet::TcpPacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);

    boost::asio::ip::tcp::socket &getTcpSocket () {
        return m_tcpSocket;
    }

    boost::asio::ip::udp::socket &getUdpSocket () {
        return m_udpSocket;
    }

    void clearGame () {
        m_game.reset();
        m_readyToStart = false;
    }

    bool isLoggedIn () const {
        return m_loggedIn;
    }

    bool isReadyToStart () const {
        return m_readyToStart;
    }

    std::string toString () const;


private:

    bool sendHeader (Packet::TcpPacketType packetType, unsigned short length);

    void readHeader ();

    void handleHeader (const boost::system::error_code &error);

    /**
     * Handles a received packet.
     **/
    void handlePacket (const boost::system::error_code &error);

    void handleLoginPacket (const SharedPacket &packet);

    void handleAnnounceGamePacket (const SharedPacket &packet);

    void handleJoinGamePacket (const SharedPacket &packet);

    void handleLeaveGamePacket (const SharedPacket &packet);

    void handleDataPacket (const SharedPacket &packet);

    void handleReadyToStartPacket (const SharedPacket &packet);

    void handleResourcePacket (const SharedPacket &packet);

    void handleKeepAlivePacket (const SharedPacket &packet);

    void broadcastGameAdded (const SharedGame &game);

    void broadcastGameRemoved (const SharedGame &game);

    boost::asio::ip::tcp::socket m_tcpSocket;

    boost::asio::ip::udp::socket m_udpSocket;

    // our player id
    unsigned int m_id;

    unsigned short m_packetType;
    unsigned short m_dataLength;
    unsigned char *m_data;

    // the player name
    std::string m_name;

    // our own statistics
    SharedStatistics m_statistics;

    // has the player logged in?
    bool m_loggedIn;

    // is the player ready to start the game
    bool m_readyToStart;

    // possible game the player is in or has announced
    SharedGame m_game;
};

typedef std::shared_ptr<PlayerHandler> SharedPlayerHandler;

#endif
