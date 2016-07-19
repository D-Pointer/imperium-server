#ifndef STATISTICS_HPP
#define STATISTICS_HPP

#include <ctime>
#include <memory>

class Statistics {

public:

    Statistics () {
        m_name = "";
        m_connected = 0;
        m_disconnected = 0;
        m_lastReceivedTcp = 0;
        m_lastSentTcp = 0;
        m_packetsSentTcp = 0;
        m_packetsReceivedTcp = 0;
        m_bytesSentTcp = 0;
        m_bytesReceivedTcp = 0;
        m_lastReceivedUdp = 0;
        m_lastSentUdp = 0;
        m_packetsSentUdp = 0;
        m_packetsReceivedUdp = 0;
        m_bytesSentUdp = 0;
        m_bytesReceivedUdp = 0;
    }

    // general info
    std::string m_name;
    time_t m_connected;
    time_t m_disconnected;

    // TCP
    time_t m_lastReceivedTcp;
    time_t m_lastSentTcp;
    unsigned int m_packetsSentTcp;
    unsigned int m_packetsReceivedTcp;
    uint64_t m_bytesSentTcp;
    uint64_t m_bytesReceivedTcp;

    // UDP
    time_t m_lastReceivedUdp;
    time_t m_lastSentUdp;
    unsigned int m_packetsSentUdp;
    unsigned int m_packetsReceivedUdp;
    uint64_t m_bytesSentUdp;
    uint64_t m_bytesReceivedUdp;
};

typedef std::shared_ptr<Statistics> SharedStatistics;

#endif
