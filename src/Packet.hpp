#ifndef IMPERIUM_SERVER_PACKET_HPP
#define IMPERIUM_SERVER_PACKET_HPP

#include <iostream>
#include <string>
#include <boost/shared_ptr.hpp>

/**
 * Packet class.
 */
class Packet {

public:

    enum PacketType {
        LoginPacket = 0,
        LoginOkPacket,
        ErrorPacket,
        AnnounceGamePacket,
        JoinGamePacket,
        LeaveGamePacket,
        GameStartsPacket,
    };

    Packet (PacketType type, const unsigned char *data, size_t dataLength);

    virtual ~Packet ();

    PacketType getType () const {
        return m_type;
    }

    size_t getDataLength () const {
        return m_dataLength;
    }

    const unsigned char *getData () const {
        return m_data;
    }


    unsigned short getUnsignedShort (size_t offset) const;

    unsigned int getUnsignedInt (size_t offset) const;

    std::string getString (size_t offset, size_t length) const;


private:

    // the packet type
    PacketType m_type;

    // raw data
    const unsigned char *m_data;
    size_t m_dataLength;
};

typedef boost::shared_ptr<Packet> SharedPacket;

#endif //IMPERIUM_SERVER_PACKET_HPP
