#ifndef PLAYER_HANDLER_HPP
#define PLAYER_HANDLER_HPP

#include <vector>
#include <memory>
#include <boost/asio.hpp>
#include <boost/signals2.hpp>
#include <boost/array.hpp>

#include "Packet.hpp"
#include "Player.hpp"

/**
 *
 **/
class PlayerHandler {
public:

    PlayerHandler (boost::asio::io_service &io_service, unsigned short udpPort);

    virtual ~PlayerHandler ();

    /**
     * Signal emitted when the session terminates.
     */
    boost::signals2::signal<void (PlayerHandler *)> terminated;

    /**
     * Starts the session. Reads the first header.
     **/
    void start ();

    boost::asio::ip::tcp::socket &getTcpSocket () {
        return m_tcpSocket;
    }

    boost::asio::ip::udp::socket &getUdpSocket () {
        return m_udpSocket;
    }

    std::string toString () const;


private:

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

    void broadcastGameAdded (const SharedGame &game, const SharedPlayer &announcer);

    void broadcastGameRemoved (const SharedGame &game);

    bool findPeerPlayer ();

    boost::asio::ip::tcp::socket m_tcpSocket;

    boost::asio::ip::udp::socket m_udpSocket;

    unsigned short m_packetType;
    unsigned short m_dataLength;
    unsigned char *m_data;

    // the player we manage as well as the peer player
    SharedPlayer m_player;
    SharedPlayer m_peer;
};

typedef std::shared_ptr<PlayerHandler> SharedPlayerHandler;

#endif
