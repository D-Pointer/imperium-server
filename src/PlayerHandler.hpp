#ifndef SESSION_HPP
#define SESSION_HPP

#include <vector>
#include <memory>
#include <boost/asio.hpp>
#include <boost/signals2.hpp>

#include "Packet.hpp"
#include "Player.hpp"

//using boost::asio::ip::tcp;

/**
 *
 **/
class PlayerHandler {
public:

    PlayerHandler (boost::asio::io_service &io_service);

    virtual ~PlayerHandler ();

    /**
     * Signal emitted when the session terminates.
     */
    boost::signals2::signal<void (PlayerHandler *)> terminated;

    /**
     * Starts the session. Reads the first header.
     **/
    void start ();

    boost::asio::ip::tcp::socket & getSocket () {
        return m_socket;
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

    void broadcastGameAdded (const SharedGame & game, const SharedPlayer & announcer);
    void broadcastGameRemoved (const SharedGame & game);

    boost::asio::ip::tcp::socket m_socket;

    unsigned short m_packetType;
    unsigned short m_dataLength;
    unsigned char *m_data;

    // the player we manage
    SharedPlayer m_player;
};

typedef std::shared_ptr<PlayerHandler> SharedPlayerHandler;

#endif
