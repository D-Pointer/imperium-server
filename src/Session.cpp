#include <iostream>

#include <boost/lexical_cast.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

#include "Session.hpp"
#include "Errors.hpp"
#include "GameManager.hpp"

unsigned int Session::m_nextId = 0;

Session::Session (boost::asio::io_service &io_service) : m_id( Session::m_nextId++ ), m_socket( io_service ), m_state(PlayerState::Connected) {

}


Session::~Session () {
    m_socket.close();
    std::cout << "Session::~Session" << std::endl;
}


tcp::socket &Session::getSocket () {
    return m_socket;
}


void Session::start () {
    // read the first header
    readHeader();
}


void Session::readHeader () {
    std::vector<boost::asio::mutable_buffer> buffers;
    buffers.push_back( boost::asio::buffer( &m_packetType, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &m_dataLength, sizeof( unsigned short )));

    std::cout << "Session::readHeader: reading header" << std::endl;

    boost::asio::async_read( m_socket, buffers, boost::bind( &Session::handleHeader, this, boost::asio::placeholders::error ));
}


void Session::handleHeader (const boost::system::error_code &error) {
    if ( error ) {
        std::cout << "Session::handleHeader: error reading header: " << error.message() << std::endl;
        terminated( this );
        return;
    }

    // convert to host order
    m_packetType = ntohs( m_packetType );
    m_dataLength = ntohs( m_dataLength );

    std::cout << "Session::handleHeader: received header for packet: " << m_packetType << ", data length: " <<
    m_dataLength << std::endl;

    // read the data, if there is anything to read
    if ( m_dataLength > 0 ) {
        m_data = new unsigned char[m_dataLength];

        // read the data
        boost::asio::async_read( m_socket, boost::asio::buffer( m_data, m_dataLength ), boost::bind( &Session::handlePacket, this, boost::asio::placeholders::error ));
    }
    else {
        // no data for this packet, handle it right away
        handlePacket( error );
    }
}


void Session::handlePacket (const boost::system::error_code &error) {
    if ( !error ) {
        // create a packet
        SharedPacket packet( new Packet((Packet::PacketType) m_packetType, m_data, m_dataLength ));

        // check the packets that we can receive
        switch ( packet->getType()) {
            case Packet::LoginPacket:
                handleLoginPacket( packet );
                break;

            case Packet::AnnounceGamePacket:
                handleAnnounceGamePacket( packet );
                break;

            case Packet::JoinGamePacket:
                handleJoinGamePacket( packet );
                break;

            case Packet::LeaveGamePacket:
                handleLeaveGamePacket( packet );
                break;

            default:
                std::cout << "Session::handlePacket: unknown packet type: " << (int) m_packetType << std::endl;
                break;
        }

        // the packet manages the data now
        m_data = 0;

        // back to reading the header
        readHeader();
    }
    else {
        std::cout << "Session::handlePacket: error reading packet data: " << error.message() << std::endl;
        terminated( this );
    }
}


void Session::handleLoginPacket (const SharedPacket &packet) {
    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( 0 );

    std::cout << "Session::handleLoginPacket: name length: " << nameLength << std::endl;

    // precautions
    if ( nameLength == 0 || nameLength > 50 ) {
        std::cout << "Session::handleLoginPacket: bad name length: " << nameLength << ", failing login" << std::endl;

        // assemble the error response packet
        std::vector<boost::asio::const_buffer> buffers;

        unsigned int netError = htons( Errors::InvalidName );
        buffers.push_back( boost::asio::buffer( &netError, sizeof( unsigned short )));

        // and send the packet
        sendPacket( Packet::ErrorPacket, buffers );
        return;
    }

    // player is now logged in
    m_state = PlayerState::LoggedIn;

    // name length is ok, get the name
    m_name = packet->getString( sizeof( nameLength ), nameLength );

    std::cout << "Session::handleLoginPacket: login from player: '" << m_name << "', id: " << m_id << std::endl;

    // assemble the response packet
    std::vector<boost::asio::const_buffer> buffers;

    unsigned int netId = htonl( m_id );
    buffers.push_back( boost::asio::buffer( &netId, sizeof( unsigned int )));

    // and send the packet
    sendPacket( Packet::LoginOkPacket, buffers );
}


void Session::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    std::cout << "Session::handleAnnounceGamePacket: received an announcement for game: " << announcedId << std::endl;
    SharedGame game( new Game( announcedId ) );
    GameManager::instance().addGame( game );

    // player has now announced a game
    m_state = PlayerState::AnnouncedGame;
}


void Session::handleJoinGamePacket (const SharedPacket &packet) {
    std::cout << "Session::handleJoinGamePacket: received a join game packet";
}


void Session::handleLeaveGamePacket (const SharedPacket &packet) {
    std::cout << "Session::handleLeaveGamePacket: received a leave game packet";
}


/*void Session::sendRemoveComponents (Data *data) {
    // how many are we nuking?
    unsigned short count =
            data->rtpSources.size() + data->rtpSinks.size() + data->mixers.size() + data->instantReplays.size() +
            data->jukeboxes.size() + data->channels.size() + data->generators.size();
    std::cout << "Session::sendRemoveComponents: removing " << count << " components" << std::endl;

    std::vector<boost::asio::const_buffer> buffers;

    unsigned short *ids = new unsigned short[count];
    int pos = 0;

    // count
    unsigned short count2 = htons( count );
    buffers.push_back( boost::asio::buffer( &count2, sizeof( unsigned short )));

    for ( unsigned int index = 0; index < data->rtpSources.size(); ++index ) {
        ids[pos++] = data->rtpSources[index]->id;
    }
    for ( unsigned int index = 0; index < data->rtpSinks.size(); ++index ) {
        ids[pos++] = data->rtpSinks[index]->id;
    }
    for ( unsigned int index = 0; index < data->mixers.size(); ++index ) {
        ids[pos++] = data->mixers[index]->id;
    }
    for ( unsigned int index = 0; index < data->instantReplays.size(); ++index ) {
        ids[pos++] = data->instantReplays[index]->id;
    }
    for ( unsigned int index = 0; index < data->jukeboxes.size(); ++index ) {
        ids[pos++] = data->jukeboxes[index]->id;
    }
    for ( unsigned int index = 0; index < data->channels.size(); ++index ) {
        ids[pos++] = data->channels[index]->id;
    }
    for ( unsigned int index = 0; index < data->generators.size(); ++index ) {
        ids[pos++] = data->generators[index]->id;
    }

    buffers.push_back( boost::asio::buffer( ids, sizeof( unsigned short ) * count ));

    // send a packet
    if ( !sendPacket( RemoveComponents, buffers )) {
        std::cout << "Session::sendRemoveComponents: error sending remove packet" << std::endl;
    }

    delete[] ids;
}*/


bool Session::sendPacket (Packet::PacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    std::cout << "Session::sendPacket: sending packet: " << packetType << std::endl;

    // send a suitable header
    sendHeader( packetType, boost::asio::buffer_size( buffers ));

    try {
        // wrap the header as a buffer and send off
        boost::asio::write( m_socket, buffers );
        std::cout << "Session::sendPacket: packet sent ok" << std::endl;

        return true;
    }
    catch (std::exception &ex) {
        std::cout << "Session::sendPacket: error sending remove packet: " << ex.what() << std::endl;
        return false;
    }
}


bool Session::sendHeader (Packet::PacketType packetType, unsigned short length) {
    // convert to network format
    unsigned short netLength = htons( length );
    unsigned short netPacketType = htons((unsigned short) packetType );

    try {
        std::vector<boost::asio::const_buffer> buffers;

        // packet type (2 bytes)
        buffers.push_back( boost::asio::buffer( &netPacketType, sizeof( unsigned short )));

        // message length (2 bytes)
        buffers.push_back( boost::asio::buffer( &netLength, sizeof( unsigned short )));

        // wrap the header as a buffer and send off
        boost::asio::write( m_socket, buffers );

        std::cout << "Session::sendHeader: sent header for packet: " << packetType << ", payload length: " << length << std::endl;
    }
    catch (std::exception &ex) {
        std::cout << "Session::sendHeader: error sending header: " << ex.what() << std::endl;
        return false;
    }

    return true;
}
