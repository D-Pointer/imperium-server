#include "Player.hpp"

unsigned int Player::m_nextId = 0;

Player::Player (boost::asio::ip::tcp::socket &tcpSocket)
        : m_id( Player::m_nextId++ ), m_tcpSocket( tcpSocket ), m_name("unknown"), m_state( PlayerState::Connected ) {
}


Player::~Player () {
    std::cout << "Player::~Player" << std::endl;
}


bool Player::sendPacket (Packet::PacketType packetType) {
    // just send a header, we have no data
    return sendHeader( packetType, 0);
}


bool Player::sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    std::cout << "Player::sendPacket: sending packet: " << Packet::getPacketName(packetType) << " to player: " << toString() << std::endl;

    // send a suitable header
    sendHeader( packetType, boost::asio::buffer_size( buffers ));

    try {
        // wrap the header as a buffer and send off
        boost::asio::write( m_tcpSocket, buffers );
        std::cout << "Player::sendPacket: packet sent ok" << std::endl;

        return true;
    }
    catch (std::exception &ex) {
        std::cout << "Player::sendPacket: error sending remove packet: " << ex.what() << std::endl;
        return false;
    }
}


bool Player::sendPacket (Packet::PacketType packetType, unsigned short value) {
    // assemble the error response packet
    std::vector<boost::asio::const_buffer> buffers;

    unsigned short netValue = htons( value );
    buffers.push_back( boost::asio::buffer( &netValue, sizeof( unsigned short )));

    // and send the packet
    return sendPacket( packetType, buffers );
}


bool Player::sendPacket (Packet::PacketType packetType, unsigned int value) {
    // assemble the error response packet
    std::vector<boost::asio::const_buffer> buffers;

    unsigned int netValue = htonl( value );
    buffers.push_back( boost::asio::buffer( &netValue, sizeof( unsigned int )));

    // and send the packet
    return sendPacket( packetType, buffers );
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

        std::cout << "Player::sendHeader: sent header for packet: " << Packet::getPacketName(packetType) << ", payload length: " << length << std::endl;
    }
    catch (std::exception &ex) {
        std::cout << "Player::sendHeader: error sending header: " << ex.what() << std::endl;
        return false;
    }

    return true;
}
