#include <iostream>
#include <sstream>

#include <boost/lexical_cast.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

#include "PlayerHandler.hpp"
#include "Errors.hpp"
#include "GameManager.hpp"
#include "PlayerManager.hpp"
#include "Definitions.hpp"

PlayerHandler::PlayerHandler (boost::asio::io_service &io_service) : m_socket( io_service ), m_data(0) {
    m_player = SharedPlayer( new Player( m_socket ));

}


PlayerHandler::~PlayerHandler () {
    m_socket.close();
    std::cout << "PlayerHandler::~PlayerHandler" << std::endl;

    // do we have a player?
    if ( m_player ) {
        // does the player have a game?
        if ( m_player->getGame()) {
            // TODO: clean up game
        }

        // TODO: clean up player
    }
}


void PlayerHandler::start () {
    // read the first header
    readHeader();
}


std::string PlayerHandler::toString () const {
    std::stringstream ss;
    ss << "[PlayerHandler " << m_player->toString() << ']';
    return ss.str();
}


void PlayerHandler::readHeader () {
    std::vector<boost::asio::mutable_buffer> buffers;
    buffers.push_back( boost::asio::buffer( &m_packetType, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &m_dataLength, sizeof( unsigned short )));

    //std::cout << "PlayerHandler::readHeader: reading header" << std::endl;

    boost::asio::async_read( m_socket, buffers, boost::bind( &PlayerHandler::handleHeader, this, boost::asio::placeholders::error ));
}


void PlayerHandler::handleHeader (const boost::system::error_code &error) {
    if ( error ) {
        std::cout << "PlayerHandler::handleHeader: error reading header: " << error.message() << std::endl;
        terminated( this );
        return;
    }

    // convert to host order
    m_packetType = ntohs( m_packetType );
    m_dataLength = ntohs( m_dataLength );

    std::cout << "PlayerHandler::handleHeader: received header for packet: " << Packet::getPacketName( m_packetType ) << ", data length: " <<
    m_dataLength << std::endl;

    // read the data, if there is anything to read
    if ( m_dataLength > 0 ) {
        m_data = new unsigned char[m_dataLength];

        // read the data
        boost::asio::async_read( m_socket, boost::asio::buffer( m_data, m_dataLength ),
                                 boost::bind( &PlayerHandler::handlePacket, this, boost::asio::placeholders::error ));
    }
    else {
        // no data for this packet, handle it right away
        handlePacket( error );
    }
}


void PlayerHandler::handlePacket (const boost::system::error_code &error) {
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
                std::cout << "PlayerHandler::handlePacket: unknown packet type: " << (int) m_packetType << std::endl;
                break;
        }

        // the packet manages the data now
        m_data = 0;

        // back to reading the header
        readHeader();
    }
    else {
        std::cout << "PlayerHandler::handlePacket: error reading packet data: " << error.message() << std::endl;
        terminated( this );
    }
}


void PlayerHandler::handleLoginPacket (const SharedPacket &packet) {
    // too many players?
    if ( PlayerManager::instance().getPlayerCount() >= s_maxPlayers ) {
        std::cout << "PlayerHandler::handleLoginPacket: server is full, failing login" << std::endl;
        m_player->sendPacket( Packet::ErrorPacket, (unsigned short) Errors::ServerFull );
        return;
    }

    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( 0 );
    std::cout << "PlayerHandler::handleLoginPacket: name length: " << nameLength << std::endl;

    // invalid name?
    if ( nameLength == 0 || nameLength > 50 ) {
        std::cout << "PlayerHandler::handleLoginPacket: bad name length: " << nameLength << ", failing login" << std::endl;
        m_player->sendPacket( Packet::ErrorPacket, (unsigned short) Errors::InvalidName );
        return;
    }

    // name length is ok, get the name
    std::string name = packet->getString( sizeof( nameLength ), nameLength );

    // name already taken?
    if ( PlayerManager::instance().isNameTaken( name )) {
        std::cout << "PlayerHandler::handleLoginPacket: name '" << name << "' is already taken, failing login" << std::endl;
        m_player->sendPacket( Packet::ErrorPacket, (unsigned short) Errors::NameTaken );
        return;
    }

    m_player->setName( name );
    m_player->setState( PlayerState::LoggedIn );
    std::cout << "PlayerHandler::handleLoginPacket: login from player: " << m_player->toString() << std::endl;

    // only now add the player to the set of connected player
    PlayerManager::instance().addPlayer( m_player );

    // assemble the response packet
    std::vector<boost::asio::const_buffer> buffers;

    unsigned int netId = htonl( m_player->getId());
    buffers.push_back( boost::asio::buffer( &netId, sizeof( unsigned int )));

    // and send the packet
    m_player->sendPacket( Packet::LoginOkPacket, buffers );

    // TODO: send all games
}


void PlayerHandler::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    std::cout << "PlayerHandler::handleAnnounceGamePacket: received an announcement for game: " << announcedId << std::endl;

    SharedGame game = m_player->getGame();

    // do we have an old game?
    if ( game ) {
        std::cout << "PlayerHandler::handleAnnounceGamePacket: removing old game: " << game->getAnnouncedId() << std::endl;
        broadcastGameRemoved( game );
        GameManager::instance().removeGame( game );
    }

    // create the new game
    game = SharedGame( new Game( announcedId ));
    m_player->setGame( game );
    GameManager::instance().addGame( game );

    // player has now announced a game
    m_player->setState( PlayerState::AnnouncedGame );

    // send out the game to everyone else
    broadcastGameAdded( game, m_player );
}


void PlayerHandler::handleJoinGamePacket (const SharedPacket &packet) {
    std::cout << "PlayerHandler::handleJoinGamePacket: received a join game packet";
}


void PlayerHandler::handleLeaveGamePacket (const SharedPacket &packet) {
    std::cout << "PlayerHandler::handleLeaveGamePacket: received a leave game packet";

    // are we in a game?
    if ( m_player->getState() == PlayerState::Playing ) {
        std::cout << "PlayerHandler::handleLeaveGamePacket: game in progress, informing other player";
        broadcastGameRemoved( m_player->getGame());
        GameManager::instance().removeGame( m_player->getGame());
        m_player->clearGame();
    }

    //m_game.reset();
}

void PlayerHandler::broadcastGameAdded (const SharedGame &game, const SharedPlayer & announcer) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the added game
    unsigned int netGameId = htonl( game->getId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    // the id of the scenario
    unsigned short netScenarioId = htons( game->getAnnouncedId());
    buffers.push_back( boost::asio::buffer( &netScenarioId, sizeof( unsigned short )));

    // name length
    std::string name = announcer->getName();
    unsigned short netnameLength = htons( name.length() );
    buffers.push_back( boost::asio::buffer( &netnameLength, sizeof( unsigned short )));

    // raw name
    buffers.push_back( boost::asio::buffer( &name[0], name.length() ));

    PlayerManager::instance().broadcastPacket( Packet::GameAddedPacket, buffers );
}


void PlayerHandler::broadcastGameRemoved (const SharedGame &game) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the removed game
    unsigned short netGameId = htons( game->getId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned short )));

    PlayerManager::instance().broadcastPacket( Packet::GameRemovedPacket, buffers );
}

