
#include "Player.hpp"
#include "Log.hpp"

unsigned int Player::m_nextId = 0;

Player::Player (boost::asio::ip::tcp::socket &tcpSocket, boost::asio::ip::udp::socket &udpSocket)
        : m_id( Player::m_nextId++ ), m_tcpSocket( tcpSocket ), m_udpSocket(udpSocket), m_name("unknown"), m_readyToStart(false) {
}


Player::~Player () {
    logDebug << "Player::~Player";
}


bool Player::sendPacket (Packet::PacketType packetType) {
    logDebug << "Player::sendPacket: sending packet [" << m_id << "]: " << Packet::getPacketName(packetType) << " to player: " << toString();

    // just send a header, we have no data
    return sendHeader( packetType, 0);
}


bool Player::sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    logDebug << "Player::sendPacket: sending packet [" << m_id << "]: " << Packet::getPacketName(packetType) << " to player: " << toString();

    // send a suitable header
    sendHeader( packetType, boost::asio::buffer_size( buffers ));

    try {
        // wrap the header as a buffer and send off
        boost::asio::write( m_tcpSocket, buffers );
        return true;
    }
    catch (std::exception &ex) {
        logError << "Player::sendPacket: error sending packet [" << m_id << "]: " << ex.what();
        return false;
    }
}


std::string Player::toString () const {
    std::stringstream ss;
    ss << "[Player " << m_id << ' ' << ( m_name != "" ? m_name : "unnamed" );
    if ( m_game ) {
        ss << " " << m_game->toString();
    }
    ss << ']';

    return ss.str();
}


bool Player::sendHeader (Packet::PacketType packetType, unsigned short length) {
    // convert to network format
    unsigned short netLength = htons( length );
    unsigned short netPacketType = htons((unsigned short) packetType );

    try {
        std::vector<boost::asio::const_buffer> buffers;

        // packet type (2 bytes)
        buffers.push_back( boost::asio::buffer( &netPacketType, sizeof( unsigned short )));

        // message length (2 bytes)
        buffers.push_back( boost::asio::buffer( &netLength, sizeof( unsigned short )));

        // wrap the header as a buffer and send off
        boost::asio::write( m_tcpSocket, buffers );

        // statistics
//        Statistics &stats = m_game->getStatistics( m_playerIndex );
//        stats.m_lastSentTcp = time(0);
//        stats.m_packetsSentTcp++;
//        stats.m_bytesSentTcp += length;

        //logDebug << "Player::sendHeader: sent header for packet: " << Packet::getPacketName(packetType); //", payload length: " << length;
    }
    catch (std::exception &ex) {
        logError << "Player::sendHeader: error sending header [" << m_id << "]: " << ex.what();
        return false;
    }

    return true;
}
