#ifndef MANAGEMENT_SERVER_HPP
#define MANAGEMENT_SERVER_HPP

#include <set>

#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include "ManagementClient.hpp"

using boost::asio::ip::tcp;

class ManagementServer {
public:
    ManagementServer (boost::asio::io_service &io_service, const std::string & ip, short port);

    void handleAccept (ManagementClient *client, const boost::system::error_code &error);


private:

    boost::asio::io_service &m_io_service;
    tcp::acceptor m_acceptor;
};


#endif
