#ifndef IMPERIUM_SERVER_PACKET_HPP
#define IMPERIUM_SERVER_PACKET_HPP

#include <iostream>
#include <string>
#include <memory>
#include <vector>

/**
 * Packet class.
 */
class Packet {
public:

    enum PacketType {
        LoginPacket = 0, // in
        LoginOkPacket, // out
        InvalidNamePacket, // error out
        NameTakenPacket, // error out
        ServerFullPacket, // error out
        AnnounceGamePacket, // in
        AnnounceOkPacket, // out
        AlreadyAnnouncedPacket, // error out
        GameAddedPacket, // out
        GameRemovedPacket, // out
        LeaveGamePacket, // in
        NoGamePacket, // error out
        JoinGamePacket, // in
        GameJoinedPacket, // out
        InvalidGamePacket, // error out
        AlreadyHasGamePacket, // error out
        GameFullPacket, // error out
        GameEndedPacket, // out
        DataPacket,
        UdpPingPacket, // UDP in
        UdpPongPacket, // UDP out
        UdpData,
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

    static std::string getPacketName (unsigned short packet);


private:

    // the packet type
    PacketType m_type;

    // raw data
    const unsigned char *m_data;
    size_t m_dataLength;

    // names of all packets
    static const std::vector<std::string> packetNames;
};

typedef std::shared_ptr<Packet> SharedPacket;

#endif //IMPERIUM_SERVER_PACKET_HPP
