#ifndef SERVER_HPP
#define SERVER_HPP

#include <set>

#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include "Player.hpp"

using boost::asio::ip::tcp;

class Server {
public:
    Server (boost::asio::io_service &io_service, const std::string &ip, short port);

    void handleAccept (Player *playerHandler, const boost::system::error_code &error);


private:

    void cleanupIdlePlayers (const boost::system::error_code &error);

    boost::asio::io_service &m_io_service;
    tcp::acceptor m_acceptor;

    // timer for cleaning up idle players periodically
    boost::asio::deadline_timer m_cleanupIdlerTimer;

    // the next available UDP port
    static unsigned short m_nextUdpPort;

    // the next player id
    static unsigned int m_nextPlayerId;
};


#endif
