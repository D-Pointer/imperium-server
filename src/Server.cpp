#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include <iostream>

#include "Server.hpp"

using boost::asio::ip::tcp;

Server::Server (boost::asio::io_service &io_service, short port)
        : m_io_service( io_service ), m_acceptor( io_service, tcp::endpoint( tcp::v4(), port )) {
    Session *session = new Session( m_io_service );
    session->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );

    // reuse addresses
    m_acceptor.set_option( boost::asio::ip::tcp::acceptor::reuse_address( true ));

    m_acceptor.async_accept( session->getSocket(),
                             boost::bind( &Server::handleAccept, this, session, boost::asio::placeholders::error ));
}


void Server::handleAccept (Session *session, const boost::system::error_code &error) {
    std::cout << "Server::handleAccept: new client" << std::endl;

    if ( !error ) {
        // start and save for later
        session->start();
        m_sessions.insert( session );
        std::cout << "Server::handleAccept: sessions now: " << m_sessions.size() << std::endl;

        // start a new session that we listen on
        session = new Session( m_io_service );
        session->terminated.connect( boost::bind( &Server::sessionTerminated, this, _1 ) );
        m_acceptor.async_accept( session->getSocket(),
                                 boost::bind( &Server::handleAccept, this, session, boost::asio::placeholders::error ));
    }
    else {
        delete session;
    }
}


void Server::sessionTerminated (Session * session) {
    std::cout << "Server::sessionTerminated: session: " << session->getId() << " terminated" << std::endl;
    m_sessions.erase( session );
    std::cout << "Server::sessionTerminated: sessions left: " << m_sessions.size() << std::endl;
}
