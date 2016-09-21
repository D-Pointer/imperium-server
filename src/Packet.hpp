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

    enum TcpPacketType {
        LoginPacket = 0, // in
        LoginOkPacket, // out
        InvalidProtocolPacket,
        AlreadyLoggedInPacket, // error out
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
        ReadyToStartPacket,
        GetResourcePacket,
        ResourcePacket,
        InvalidResourceNamePacket,
        InvalidResourcePacket,
        KeepAlivePacket,
        PlayerCountPacket,
    };

    enum UdpPacketType {
        UdpPingPacket = 0, // UDP in
        UdpPongPacket, // UDP out
        UdpDataPacket,
        UdpStartActionPacket,
    };

    static bool isValidPacket (unsigned short value) {
        return value <= TcpPacketType::PlayerCountPacket;
    }

    Packet (TcpPacketType type, const unsigned char *data, size_t dataLength);

    virtual ~Packet ();

    TcpPacketType getType () const {
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
    TcpPacketType m_type;

    // raw data
    const unsigned char *m_data;
    size_t m_dataLength;

    // names of all packets
    static const std::vector<std::string> packetNames;
};

typedef std::shared_ptr<Packet> SharedPacket;

#endif //IMPERIUM_SERVER_PACKET_HPP
