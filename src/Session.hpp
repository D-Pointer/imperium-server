#ifndef SESSION_HPP
#define SESSION_HPP

#include <vector>
#include <boost/asio.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/signals2.hpp>

#include "Packet.hpp"
#include "PlayerState.hpp"

using boost::asio::ip::tcp;

/**
 *
 **/
class Session {
public:

    Session (boost::asio::io_service &io_service);

    virtual ~Session ();

    /**
     * Returns the TCP getSocket connected to the player.
     */
    tcp::socket &getSocket ();

    /**
     * Returns the player unique id.
     */
    unsigned int getId () const {
        return m_id;
    }

    /**
     * Signal emitted when the session terminates.
     */
    boost::signals2::signal<void (Session *)> terminated;

    /**
     * Starts the session. Reads the first header.
     **/
    void start ();


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

    void handleResult ();

    bool sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);

    bool sendHeader (Packet::PacketType packetType, unsigned short length);


    unsigned int m_id;
    static unsigned int m_nextId;

    tcp::socket m_socket;
    unsigned short m_packetType;
    unsigned short m_dataLength;
    unsigned char *m_data;

    // the player name
    std::string m_name;

    // the player's state
    PlayerState m_state;
};

typedef boost::shared_ptr<Session> SharedSession;

#endif
