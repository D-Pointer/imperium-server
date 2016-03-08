
#ifndef PLAYER_HPP
#define PLAYER_HPP

#include <memory>
#include <boost/asio.hpp>

#include "PlayerState.hpp"
#include "Game.hpp"
#include "Packet.hpp"

class Player {

public:

    Player (boost::asio::ip::tcp::socket &tcpSocket);

    ~Player ();

    /**
     * Returns the TCP getSocket connected to the player.
     */
    boost::asio::ip::tcp::socket &getSocket () {
        return m_tcpSocket;
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

    PlayerState getState () const {
        return m_state;
    }

    void setState (PlayerState state) {
        m_state = state;
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

    bool sendPacket (Packet::PacketType packetType);

    bool sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers);

    bool sendPacket (Packet::PacketType packetType, unsigned short value);

    bool sendPacket (Packet::PacketType packetType, unsigned int value);

    std::string toString () const;


private:

    bool sendHeader (Packet::PacketType packetType, unsigned short length);

    unsigned int m_id;
    static unsigned int m_nextId;

    boost::asio::ip::tcp::socket &m_tcpSocket;

    // the player name
    std::string m_name;

    // the player's state
    PlayerState m_state;

    // possible game the player is in or has announced
    SharedGame m_game;

    // the possible peer the player has
    std::shared_ptr<Player> m_peer;
};

typedef std::shared_ptr<Player> SharedPlayer;

#endif //IMPERIUM_SERVER_PLAYER_HPP
