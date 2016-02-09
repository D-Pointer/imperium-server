#include <iostream>

#include "Packet.hpp"

Packet::Packet (PacketType type, const unsigned char *data, size_t dataLength)
        : m_type( type ), m_data( data ),
          m_dataLength( dataLength ) {
    std::cout << "Packet::Packet: creating a packet: " << type << ", data size: " << dataLength << std::endl;
}


Packet::~Packet () {
    if ( m_data ) {
        delete[] m_data;
        m_data = 0;
    }
}


unsigned short Packet::getUnsignedShort (size_t offset) const {
    unsigned short value;

    if ( offset + sizeof( unsigned short ) > m_dataLength ) {
        std::cout << "Packet::getUnsignedShort: out of bounds! Offset: " << offset << ", type size: " <<
        sizeof( unsigned short )
        << ", data length: " << m_dataLength << std::endl;
        return value;
    }

    memcpy( &value, m_data + offset, sizeof( unsigned short ));
    return ntohs( value );
}


unsigned int Packet::getUnsignedInt (size_t offset) const {
    unsigned int value;

    if ( offset + sizeof( unsigned int ) > m_dataLength ) {
        std::cout << "Packet::getUnsignedInt: out of bounds! Offset: " << offset << ", type size: " <<
        sizeof( unsigned int )
        << ", data length: " << m_dataLength << std::endl;
        return value;
    }

    memcpy( &value, m_data + offset, sizeof( unsigned int ));
    return ntohl( value );
}


std::string Packet::getString (size_t offset, size_t length) const {
    if ( offset + length > m_dataLength ) {
        std::cout << "Packet::getString: out of bounds! Offset: " << offset << ", length: " << length
        << ", data length: " << m_dataLength << std::endl;
        return "";
    }

    return std::string((const char *) ( m_data + offset ), length );
}

