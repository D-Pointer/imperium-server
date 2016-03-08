#include <iostream>
#include <sstream>

#include <boost/lexical_cast.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

#include "PlayerHandler.hpp"
#include "GameManager.hpp"
#include "PlayerManager.hpp"
#include "Definitions.hpp"

PlayerHandler::PlayerHandler (boost::asio::io_service &io_service) : m_socket( io_service ), m_data( 0 ) {
    m_player = std::make_shared<Player>( m_socket );

}


PlayerHandler::~PlayerHandler () {
    m_socket.close();
    std::cout << "PlayerHandler::~PlayerHandler" << std::endl;

    // do we have a player?
    if ( m_player ) {
        // clean up player
        PlayerManager::instance().removePlayer( m_player );

        // does the player have a game?
        if ( m_player->getGame()) {
            GameManager::instance().removeGame( m_player->getGame());
            broadcastGameRemoved( m_player->getGame());
        }

        m_player.reset();
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

//            case Packet::JoinGamePacket:
//                handleJoinGamePacket( packet );
//                break;
//
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
        m_player->sendPacket( Packet::ServerFullPacket );
        return;
    }

    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( 0 );

    // invalid name?
    if ( nameLength == 0 || nameLength > 50 ) {
        std::cout << "PlayerHandler::handleLoginPacket: bad name length: " << nameLength << ", failing login" << std::endl;
        m_player->sendPacket( Packet::InvalidNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string name = packet->getString( sizeof( nameLength ), nameLength );

    // name already taken?
    if ( PlayerManager::instance().isNameTaken( name )) {
        std::cout << "PlayerHandler::handleLoginPacket: name '" << name << "' is already taken, failing login" << std::endl;
        m_player->sendPacket( Packet::NameTakenPacket );
        return;
    }

    m_player->setName( name );
    m_player->setState( PlayerState::LoggedIn );
    std::cout << "PlayerHandler::handleLoginPacket: login from player: " << m_player->toString() << std::endl;

    // only now add the player to the set of connected player
    PlayerManager::instance().addPlayer( m_player );

    // player login ok
    m_player->sendPacket( Packet::LoginOkPacket );

    // send all current games as "game added" packets
    for ( auto game : GameManager::instance().getAllGames()) {
        std::vector<boost::asio::const_buffer> buffers;

        // the id of the added game
        unsigned int netGameId = htonl( game->getGameId());
        buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

        // the id of the scenario
        unsigned short netScenarioId = htons( game->getScenariodId());
        buffers.push_back( boost::asio::buffer( &netScenarioId, sizeof( unsigned short )));

        // get the player owning the game
        SharedPlayer owner = PlayerManager::instance().getPlayer( game->getPlayerId());
        if ( !owner ) {
            continue;
        }

        // name length
        std::string name = owner->getName();
        unsigned short netnameLength = htons( name.length());
        buffers.push_back( boost::asio::buffer( &netnameLength, sizeof( unsigned short )));

        // raw name
        buffers.push_back( boost::asio::buffer( &name[0], name.length()));

        // send to the logged in player
        std::cout << "PlayerHandler::handleLoginPacket: sending game: " << game->toString() << " to player: " << m_player->toString() << std::endl;
        m_player->sendPacket( Packet::GameAddedPacket, buffers );
    }
}


void PlayerHandler::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    std::cout << "PlayerHandler::handleAnnounceGamePacket: received an announcement for game: " << announcedId << std::endl;

    SharedGame game = m_player->getGame();

    // do we have an old game?
    if ( game ) {
        std::cout << "PlayerHandler::handleAnnounceGamePacket: old game already announced: " << game->getScenariodId() << ", can not announce new" << std::endl;
        m_player->sendPacket( Packet::AlreadyAnnouncedPacket );
        return;
    }

    // create the new game
    game = std::make_shared<Game>( announcedId, m_player->getId());
    m_player->setGame( game );
    GameManager::instance().addGame( game );

    // player has now announced a game
    m_player->setState( PlayerState::AnnouncedGame );

    // all ok, send a response with the announced game id
    std::vector<boost::asio::const_buffer> buffers;
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));
    m_player->sendPacket( Packet::AnnounceOkPacket, buffers );

    // send out the game to everyone
    broadcastGameAdded( game, m_player );
}


void PlayerHandler::handleJoinGamePacket (const SharedPacket &packet) {
    std::cout << "PlayerHandler::handleJoinGamePacket: received a join game packet";
}


void PlayerHandler::handleLeaveGamePacket (const SharedPacket &packet) {
    std::cout << "PlayerHandler::handleLeaveGamePacket: received a leave game packet";

    if ( !m_player->getGame()) {
        // no game, can't leave
        m_player->sendPacket( Packet::NoGamePacket );
        return;
    }

    // are we in a game?
    if ( m_player->getState() == PlayerState::Playing ) {
        std::cout << "PlayerHandler::handleLeaveGamePacket: game in progress, informing other player";
    }

    GameManager::instance().removeGame( m_player->getGame());
    broadcastGameRemoved( m_player->getGame());
    m_player->clearGame();
}


void PlayerHandler::broadcastGameAdded (const SharedGame &game, const SharedPlayer &announcer) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the added game
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    // the id of the scenario
    unsigned short netScenarioId = htons( game->getScenariodId());
    buffers.push_back( boost::asio::buffer( &netScenarioId, sizeof( unsigned short )));

    // name length
    std::string name = announcer->getName();
    unsigned short netnameLength = htons( name.length());
    buffers.push_back( boost::asio::buffer( &netnameLength, sizeof( unsigned short )));

    // raw name
    buffers.push_back( boost::asio::buffer( &name[0], name.length()));

    // send to everyone
    PlayerManager::instance().broadcastPacket( Packet::GameAddedPacket, buffers );
}


void PlayerHandler::broadcastGameRemoved (const SharedGame &game) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the removed game
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    PlayerManager::instance().broadcastPacket( Packet::GameRemovedPacket, buffers );
}

