#include <boost/asio.hpp>
#include <boost/bind.hpp>

#include "UdpHandler.hpp"
#include "Packet.hpp"
#include "Log.hpp"

UdpHandler::UdpHandler (udp::socket &socket1, udp::socket &socket2, boost::asio::ip::address address1, boost::asio::ip::address address2, Statistics &stats1,
                        Statistics &stats2)
        : m_socket1( socket1 ), m_socket2( socket2 ), m_playerSentUdp1( false ), m_playerSentUdp2( false ), m_address1( address1 ), m_address2( address2 ),
          m_stats1( stats1 ), m_stats2( stats2 ) {

}


UdpHandler::~UdpHandler () {
    logDebug << "UdpHandler::~UdpHandler";
}


void UdpHandler::start () {
    // start receiving on both sockets. note the use of shared_from_this() which makes the life time handling easier. When operations are cancelled
    // on the socket the PlayerHandler can drop the shared pointer and Boost will keep this object alive until the callbacks run with an error.
    m_socket1.async_receive_from( boost::asio::buffer( m_udpReceiveBuffer1 ), m_endpoint1,
                                  boost::bind( &UdpHandler::handleUdpReceive1, shared_from_this(),
                                               boost::asio::placeholders::error,
                                               boost::asio::placeholders::bytes_transferred ));

    m_socket2.async_receive_from( boost::asio::buffer( m_udpReceiveBuffer2 ), m_endpoint2,
                                  boost::bind( &UdpHandler::handleUdpReceive2, shared_from_this(),
                                               boost::asio::placeholders::error,
                                               boost::asio::placeholders::bytes_transferred ));
    logDebug << "UdpHandler::start: handler started, ready to handle UDP data";
}


void UdpHandler::sendStartPackets () {
    // have both players sent a first UDP packet?
    if ( !m_playerSentUdp1 ) {
        logWarning << "UdpHandler::sendStartPackets: player 1 has not sent an initial UDP packet, can not send start packet";
        return;
    }
    if ( !m_playerSentUdp2 ) {
        logWarning << "UdpHandler::sendStartPackets: player 2 has not sent an initial UDP packet, can not send start packet";
        return;
    }

    logDebug << "UdpHandler::sendStartPackets: sending starts packets to both players";

    std::vector<boost::asio::const_buffer> buffers;

    // packet type
    unsigned char netPacketType = Packet::PacketType::UdpStartActionPacket;
    buffers.push_back( boost::asio::buffer( &netPacketType, sizeof( unsigned short )));

    // data length type
    unsigned short netDataLength = htons( 0 );
    buffers.push_back( boost::asio::buffer( &netDataLength, sizeof( unsigned short )));

    // send to both players
    m_socket1.send_to( buffers, m_endpoint1 );
    m_socket2.send_to( buffers, m_endpoint2 );

    // statistics
    m_stats1.m_lastSentUdp = time( 0 );
    m_stats1.m_packetsSentUdp++;
    m_stats1.m_bytesSentUdp += sizeof( unsigned short ) * 2;

    m_stats2.m_lastSentUdp = m_stats1.m_lastSentUdp;
    m_stats2.m_packetsSentUdp++;
    m_stats2.m_bytesSentUdp += sizeof( unsigned short ) * 2;
}


void UdpHandler::handleUdpReceive1 (const boost::system::error_code &error, size_t size) {
    // on error we do not try to receive again
    if ( error ) {
        logWarning << "UdpHandler::handleUdpReceive1: error receiving UDP data from player 1: " << error.message();
        return;
    }

//    logDebug << "UdpHandler::handleUdpReceive1: received " << size << " bytes of UDP data from player 1, "
//    << m_endpoint1.address().to_string() << ":" << m_endpoint1.port();

    handlePacket( m_udpReceiveBuffer1, size, 1 );

    // receive the next packet
    m_socket1.async_receive_from( boost::asio::buffer( m_udpReceiveBuffer1 ), m_endpoint1,
                                  boost::bind( &UdpHandler::handleUdpReceive1, shared_from_this(),
                                               boost::asio::placeholders::error,
                                               boost::asio::placeholders::bytes_transferred ));
}


void UdpHandler::handleUdpReceive2 (const boost::system::error_code &error, size_t size) {
    // on error we do not try to receive again
    if ( error ) {
        logWarning << "UdpHandler::handleUdpReceive2: error receiving UDP data from player 2: " << error.message();
        return;
    }

//    logDebug << "UdpHandler::handleUdpReceive2: received " << size << " bytes of UDP data from player 2, "
//    << m_endpoint2.address().to_string() << ":" << m_endpoint2.port();

    handlePacket( m_udpReceiveBuffer2, size, 2 );

    // receive the next packet
    m_socket2.async_receive_from( boost::asio::buffer( m_udpReceiveBuffer2 ), m_endpoint2,
                                  boost::bind( &UdpHandler::handleUdpReceive2, shared_from_this(),
                                               boost::asio::placeholders::error,
                                               boost::asio::placeholders::bytes_transferred ));
}


void UdpHandler::handlePacket (boost::array<char, 4096> &data, size_t size, unsigned int sender) {
    if ( data.size() < sizeof( unsigned short )) {
        logError << "UdpHandler::handlePacket: too short packet from player " << sender;
        return;
    }

    // statistics
    Statistics &stats = sender == 1 ?m_stats1 : m_stats2;
    stats.m_lastReceivedUdp = time( 0 );
    stats.m_packetsReceivedUdp++;
    stats.m_bytesReceivedUdp += size;

    // handle the first UDP packet
    if ( sender == 1 ) {
        m_playerSentUdp1 = true;
    }
    else {
        m_playerSentUdp2 = true;
    }

    unsigned char packetType = data[0];

    switch ((Packet::PacketType) packetType ) {
        case Packet::UdpPingPacket:
            logDebug << "UdpHandler::handlePacket: UDP ping from player " << sender;
            if ( sender == 1 ) {
                handlePing( data, size, m_socket1, m_endpoint1, stats );
            }
            else {
                handlePing( data, size, m_socket2, m_endpoint2, stats );
            }
            break;

        case Packet::UdpDataPacket:
            logDebug << "UdpHandler::handlePacket: " << size << " bytes of UDP data from player " << sender;
            if ( sender == 1 ) {
                // we can only send to player 2 if that player has sent us at least one packet so that the endpoint is valid
                if ( !m_playerSentUdp2 ) {
                    logWarning << "UdpHandler::handlePacket: player 2 has not yet sent their first UDP packet, can not send";
                    return;
                }

                handleData( data, size, m_socket1, m_endpoint2, stats );
            }
            else {
                if ( !m_playerSentUdp1 ) {
                    logWarning << "UdpHandler::handlePacket: player 1 has not yet sent their first UDP packet, can not send";
                    return;
                }

                handleData( data, size, m_socket2, m_endpoint1, stats );
            }
            break;

        default:
            logError << "UdpHandler::handlePacket: unknown packet from player " << sender << ", size: " << size << " bytes";
            return;
    }
}


void UdpHandler::handlePing (boost::array<char, 4096> &data, size_t size, udp::socket &socket, udp::endpoint &receiver, Statistics &stats) {
    // for the response we change the packet type to a "pong"
    unsigned char packetType = Packet::PacketType::UdpPongPacket;
    //packetType = htons( packetType );
    data[0] = packetType;
    //memcpy( data.data(), &packetType, sizeof( unsigned short ));

    // send away
    socket.send_to( boost::asio::buffer( data, size ), receiver );

    // statistics
    stats.m_lastSentUdp = time( 0 );
    stats.m_packetsSentUdp++;
    stats.m_bytesSentUdp += size;
}


void UdpHandler::handleData (boost::array<char, 4096> &data, size_t size, udp::socket &socket, udp::endpoint &receiver, Statistics &stats) {
    // send away
    socket.send_to( boost::asio::buffer( data, size ), receiver );

    // statistics
    stats.m_lastSentUdp = time( 0 );
    stats.m_packetsSentUdp++;
    stats.m_bytesSentUdp += size;
}
