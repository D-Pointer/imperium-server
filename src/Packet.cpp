
#include <arpa/inet.h>

#include <cstring>
#include <sstream>

#include "Packet.hpp"
#include "Log.hpp"

const std::vector<std::string> Packet::packetNames = {
        "LoginPacket",
        "LoginOkPacket",
        "InvalidProtocolPacket",
	"AlreadyLoggedIn",
        "InvalidNamePacket",
        "NameTakenPacket",
        "ServerFullPacket",
        "AnnounceGamePacket",
        "AnnounceOkPacket",
        "AlreadyAnnouncedPacket",
        "GameAddedPacket",
        "GameRemovedPacket",
        "LeaveGamePacket",
        "NoGamePacket",
        "JoinGamePacket",
        "GameJoinedPacket",
        "InvalidGamePacket",
        "AlreadyHasGamePacket",
        "GameFullPacket",
        "GameEndedPacket",
        "DataPacket",
        "ReadyToStartPacket",
        "GetResourcePacket",
        "ResourcePacket",
        "InvalidResourcePacket",
};


Packet::Packet (TcpPacketType type, const unsigned char *data, size_t dataLength)
        : m_type( type ), m_data( data ),
          m_dataLength( dataLength ) {
    logDebug << "Packet::Packet: creating a packet: " << Packet::getPacketName(type) << ", data size: " << dataLength;
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
        logError << "Packet::getUnsignedShort: out of bounds! Offset: " << offset << ", type size: " << sizeof( unsigned short ) << ", data length: " <<
        m_dataLength;
        return value;
    }

    memcpy( &value, m_data + offset, sizeof( unsigned short ));
    return ntohs( value );
}


unsigned int Packet::getUnsignedInt (size_t offset) const {
    unsigned int value;

    if ( offset + sizeof( unsigned int ) > m_dataLength ) {
        logError << "Packet::getUnsignedInt: out of bounds! Offset: " << offset << ", type size: " << sizeof( unsigned int ) << ", data length: " <<
        m_dataLength;
        return value;
    }

    memcpy( &value, m_data + offset, sizeof( unsigned int ));
    return ntohl( value );
}


std::string Packet::getString (size_t offset, size_t length) const {
    if ( offset + length > m_dataLength ) {
        logError << "Packet::getString: out of bounds! Offset: " << offset << ", length: " << length << ", data length: " << m_dataLength;
        return "";
    }

    return std::string((const char *) ( m_data + offset ), length );
}


std::string Packet::getPacketName (unsigned short packetType) {
    if ( packetType >= Packet::packetNames.size()) {
        std::stringstream ss;
        ss << "invalid packet: " << packetType;
        return ss.str();
    }

    return Packet::packetNames[packetType];
}
