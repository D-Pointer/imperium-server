#ifndef UDP_HANDLER_HPP
#define UDP_HANDLER_HPP

#include <memory>

#include <boost/asio/ip/udp.hpp>
#include <boost/array.hpp>

#include "Statistics.hpp"

using boost::asio::ip::udp;


class UdpHandler : public std::enable_shared_from_this<UdpHandler> {

public:


    UdpHandler (unsigned int gameId, udp::socket &socket1, udp::socket &socket2, boost::asio::ip::address address1, boost::asio::ip::address address2,
                Statistics &stats1, Statistics &stats2);

    virtual ~UdpHandler ();

    void start ();

    void stop ();

    void sendStartPackets ();


private:

    void handleUdpReceive1 (const boost::system::error_code &error, size_t size);

    void handleUdpReceive2 (const boost::system::error_code &error, size_t size);

    void handlePacket (boost::array<char, 4096> &data, size_t size, unsigned int sender);

    void handlePing (boost::array<char, 4096> &data, size_t size, udp::socket &socket, udp::endpoint &receiver, Statistics &stats);

    void handleData (boost::array<char, 4096> &data, size_t size, udp::socket &socket, udp::endpoint &receiver, Statistics &stats);

    unsigned int m_gameId;

    udp::socket &m_socket1;
    udp::socket &m_socket2;

    Statistics & m_stats1;
    Statistics & m_stats2;

    // have both players sent their initial udp data?
    bool m_playerSentUdp1;
    bool m_playerSentUdp2;

    boost::asio::ip::address m_address1;
    boost::asio::ip::address m_address2;

    boost::asio::ip::udp::endpoint m_endpoint1;
    boost::asio::ip::udp::endpoint m_endpoint2;
    boost::array<char, 4096> m_udpReceiveBuffer1;
    boost::array<char, 4096> m_udpReceiveBuffer2;
};

typedef std::shared_ptr<UdpHandler> SharedUdpHandler;

#endif //IMPERIUM_SERVER_UDPHANDLER_HPP
