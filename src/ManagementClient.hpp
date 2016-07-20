#ifndef MANAGEMENT_CLIENT_HPP
#define MANAGEMENT_CLIENT_HPP

#include <boost/asio.hpp>

/**
 *
 **/
class ManagementClient {
public:

    ManagementClient (boost::asio::io_service &io_service);

    virtual ~ManagementClient ();

    boost::asio::ip::tcp::socket &getTcpSocket () {
        return m_tcpSocket;
    }

    /**
     * Starts the session. Reads the first header.
     **/
    void start ();


private:

    void handleRequest (const boost::system::error_code &error, std::size_t bytesTransferred);

    void handleStatus ();

    void handleGames ();

    void handlePlayers ();

        void handleQuit ();

    bool sendResponse (const std::string & response);

        boost::asio::ip::tcp::socket m_tcpSocket;

    // buffer we read into
    boost::asio::streambuf m_buffer;
};

typedef std::shared_ptr<ManagementClient> SharedManagementClient;

#endif
