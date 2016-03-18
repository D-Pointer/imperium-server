#ifndef SERVER_HPP
#define SERVER_HPP

#include <set>

#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include "PlayerHandler.hpp"

using boost::asio::ip::tcp;

class Server {
public:
    Server (boost::asio::io_service &io_service, const std::string & ip, short port);

    void handleAccept (PlayerHandler *playerHandler, const boost::system::error_code &error);


private:

    void sessionTerminated (PlayerHandler * playerHandler);

    boost::asio::io_service &m_io_service;
    tcp::acceptor m_acceptor;

    std::set<PlayerHandler *> m_playerHandlers;

    // the next available UDP port
    static unsigned short m_nextUdpPort;
};


#endif
