
#include <sstream>

#include <boost/lexical_cast.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

#include "PlayerHandler.hpp"
#include "ResourceLoader.hpp"
#include "GameManager.hpp"
#include "PlayerManager.hpp"
#include "Definitions.hpp"
#include "Log.hpp"

using boost::asio::ip::udp;

PlayerHandler::PlayerHandler (boost::asio::io_service &io_service, unsigned short udpPort) : m_tcpSocket( io_service ),
                                                                                             m_udpSocket( io_service, udp::endpoint( udp::v4(), udpPort )),
                                                                                             m_data( 0 ) {
    m_player = std::make_shared<Player>( m_tcpSocket, m_udpSocket );
}


PlayerHandler::~PlayerHandler () {
    m_tcpSocket.close();
    m_udpSocket.close();

    logDebug << "PlayerHandler::~PlayerHandler [" << m_player->getId() << "]";

    // do we have a player?
    if ( m_player ) {
        // does the player have a game?
        SharedGame game = m_player->getGame();
        if ( game ) {
            // has the game started?
            if ( game->hasStarted()) {
                // let the other player know it ended
                SharedPlayer player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
                if ( player1 && player1 != m_player ) {
                    player1->sendPacket( Packet::GameEndedPacket );
                    player1->clearGame();
                    player1->setReadyToStart( false );

                    logDebug << "PlayerHandler::~PlayerHandler [" << m_player->getId() << "]: clearing game for player 1";
                }

                SharedPlayer player2 = PlayerManager::instance().getPlayer( game->getPlayerId2());
                if ( player2 && player2 != m_player ) {
                    player2->sendPacket( Packet::GameEndedPacket );
                    player2->clearGame();
                    player2->setReadyToStart( false );
                    logDebug << "PlayerHandler::~PlayerHandler [" << m_player->getId() << "]: clearing game for player 2";
                }

                // set the game end time
                game->endGame();
            }
            else {
                // not started, so it was still looking for players, but not anymore
                broadcastGameRemoved( game );
            }

            GameManager::instance().removeGame( game );
        }

        // clean up player
        PlayerManager::instance().removePlayer( m_player );
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

    //logDebug << "PlayerHandler::readHeader: reading header" 

    boost::asio::async_read( m_tcpSocket, buffers, boost::bind( &PlayerHandler::handleHeader, this, boost::asio::placeholders::error ));
}


void PlayerHandler::handleHeader (const boost::system::error_code &error) {
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << "PlayerHandler::handleHeader [" << m_player->getId() << "]: connection closed";
        }
        else {
            logError << "PlayerHandler::handleHeader [" << m_player->getId() << "]: error reading header: " << error.message();
        }

        terminated( this );
        return;
    }

    // convert to host order
    m_packetType = ntohs( m_packetType );
    m_dataLength = ntohs( m_dataLength );

    // precautions
    if ( !Packet::isValidPacket( m_packetType )) {
        logError << "PlayerHandler::handleHeader [" << m_player->getId() << "]: invalid packet: " << m_packetType << ", closing connection";
        terminated( this );
        return;
    }

    logDebug << "PlayerHandler::handleHeader [" << m_player->getId() << "]: received header for packet: " << Packet::getPacketName( m_packetType ) <<
    ", data length: " << m_dataLength;

    // read the data, if there is anything to read
    if ( m_dataLength > 0 ) {
        m_data = new unsigned char[m_dataLength];

        // read the data
        boost::asio::async_read( m_tcpSocket, boost::asio::buffer( m_data, m_dataLength ),
                                 boost::bind( &PlayerHandler::handlePacket, this, boost::asio::placeholders::error ));
    }
    else {
        // no data for this packet, handle it right away
        handlePacket( error );
    }
}


void PlayerHandler::handlePacket (const boost::system::error_code &error) {
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << "PlayerHandler::handleHeader [" << m_player->getId() << "]: connection closed";
        }
        else {
            logError << "PlayerHandler::handlePacket [" << m_player->getId() << "]: error reading packet data: " << error.message();
        }

        terminated( this );
        return;
    }

    // create a packet
    SharedPacket packet = std::make_shared<Packet>((Packet::TcpPacketType) m_packetType, m_data, m_dataLength );

    // statistics
//        Statistics &stats = m_player->getStatistics();
//        stats.m_lastReceivedTcp = time( 0 );
//        stats.m_packetsReceivedTcp++;
//        stats.m_bytesReceivedTcp += sizeof( unsigned short ) * 2 + m_dataLength;

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

        case Packet::DataPacket:
            handleDataPacket( packet );
            break;

        case Packet::ReadyToStartPacket:
            handleReadyToStartPacket( packet );
            break;

        case Packet::GetResourcePacket:
            handleResourcePacket( packet );
            break;

        default:
            logError << "PlayerHandler::handlePacket [" << m_player->getId() << "]: unknown packet type: " << (int) packet->getType();
            break;
    }

    // the packet manages the data now
    m_data = 0;

    // back to reading the header
    readHeader();
}


void PlayerHandler::handleLoginPacket (const SharedPacket &packet) {
    // too many players?
    if ( PlayerManager::instance().getPlayerCount() >= s_maxPlayers ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: server is full, failing login";
        m_player->sendPacket( Packet::ServerFullPacket );
        return;
    }

    unsigned int offset = 0;

    // get the protocol version
    unsigned short protocolVersion = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // wrong protocol version?
    if ( protocolVersion != s_protocolVersion ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: bad protocol: " << protocolVersion << ", we support: " <<
        s_protocolVersion;
        m_player->sendPacket( Packet::InvalidProtocolPacket );
        return;
    }

    // already logged in?
    if ( m_player->isLoggedIn() ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: has already logged in as: " << m_player->getName() << ", failing login";
        m_player->sendPacket( Packet::AlreadyLoggedInPacket );
        return;
    }

    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // invalid name?
    if ( nameLength == 0 || nameLength > 50 ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: bad name length: " << nameLength << ", failing login";
        m_player->sendPacket( Packet::InvalidNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string name = packet->getString( offset, nameLength );

    // name already taken?
    if ( PlayerManager::instance().isNameTaken( name )) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: name '" << name << "' is already taken, failing login";
        m_player->sendPacket( Packet::NameTakenPacket );
        return;
    }

    m_player->setName( name );
    logDebug << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: login from player: " << m_player->toString();

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
        SharedPlayer owner = PlayerManager::instance().getPlayer( game->getPlayerId1());
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
        logDebug << "PlayerHandler::handleLoginPacket [" << m_player->getId() << "]: sending game: " << game->toString() << " to player: " <<
        m_player->toString();
        m_player->sendPacket( Packet::GameAddedPacket, buffers );
    }
}


void PlayerHandler::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    logDebug << "PlayerHandler::handleAnnounceGamePacket [" << m_player->getId() << "]: received an announcement for game: " << announcedId;

    SharedGame game = m_player->getGame();

    // do we have an old game?
    if ( game ) {
        logWarning << "PlayerHandler::handleAnnounceGamePacket [" << m_player->getId() << "]: old game already announced: " << game->getScenariodId() <<
        ", can not announce new";
        m_player->sendPacket( Packet::AlreadyAnnouncedPacket );
        return;
    }

    // create the new game, we're player 1
    game = GameManager::instance().createGame( announcedId, m_player->getId());
    m_player->setGame( game, 0 );

    // all ok, send a response with the announced game id
    std::vector<boost::asio::const_buffer> buffers;
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));
    m_player->sendPacket( Packet::AnnounceOkPacket, buffers );

    // send out the game to everyone
    broadcastGameAdded( game, m_player );
}


void PlayerHandler::handleJoinGamePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: received a join game packet";

    // do we have a game?
    if ( m_player->getGame()) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: already have a game: " << m_player->getGame()->getScenariodId() <<
        ", can not join";
        m_player->sendPacket( Packet::AlreadyHasGamePacket );
        return;
    }

    // get the game id
    unsigned int gameId = packet->getUnsignedInt( 0 );

    // do we have such a game?
    SharedGame game = GameManager::instance().getGame( gameId );
    if ( !game ) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: no game with id: " << gameId;
        m_player->sendPacket( Packet::InvalidGamePacket );
        return;
    }

    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: player: " << m_player->toString() << " wants to join game: " <<
    game->toString();

    // has the game already started?
    if ( game->hasStarted()) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: game: " << game->toString() << " has already started, can not join";
        m_player->sendPacket( Packet::GameFullPacket );
        return;
    }

    // find the first, owning player
    SharedPlayer player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
    if ( !player1 ) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: owner player not found for game: " << game->toString();
        m_player->sendPacket( Packet::InvalidGamePacket );
        return;
    }

    // game, meet player, we're player 2
    game->setPlayerId2( m_player->getId());
    m_player->setGame( game, 1 );

    // create the UDP handler
    boost::system::error_code ec1, ec2;
    boost::asio::ip::tcp::endpoint ep1 = player1->getTcpSocket().remote_endpoint( ec1 );
    boost::asio::ip::tcp::endpoint ep2 = m_player->getTcpSocket().remote_endpoint( ec2 );

    if ( ec1 ) {
        logError << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: failed to get player 1 TCP endpoint" << ec1.message();
        return;
    }
    if ( ec2 ) {
        logError << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: failed to get player 2 TCP endpoint: " << ec2.message();
        return;
    }

    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_player->getId() << "]: endpoint 1: " << ep1.address() << ", endpoint 2: " << ep2.address();

    // set up the UDP handler
    SharedUdpHandler udpHandler = std::make_shared<UdpHandler>( player1->getUdpSocket(), m_player->getUdpSocket(), ep1.address(), ep2.address(),
                                                                game->getStatistics( 0 ), game->getStatistics( 1 ));
    m_player->getGame()->setUdpHandler( udpHandler );
    udpHandler->start();

    // send to both players that the game has been joined
    std::vector<boost::asio::const_buffer> buffers1;

    unsigned short netPort1 = htons( m_player->getUdpSocket().local_endpoint().port());
    buffers1.push_back( boost::asio::buffer( &netPort1, sizeof( unsigned short )));

    std::string name1 = m_player->getName();
    unsigned short netNameLength1 = htons( name1.length());
    buffers1.push_back( boost::asio::buffer( &netNameLength1, sizeof( unsigned short )));
    buffers1.push_back( boost::asio::buffer( &name1[0], name1.length()));
    player1->sendPacket( Packet::GameJoinedPacket, buffers1 );

    std::vector<boost::asio::const_buffer> buffers2;

    // CRASH
    unsigned short netPort2 = htons( player1->getUdpSocket().local_endpoint().port());
    buffers2.push_back( boost::asio::buffer( &netPort2, sizeof( unsigned short )));

    std::string name2 = player1->getName();
    unsigned short netNameLength2 = htons( name2.length());
    buffers2.push_back( boost::asio::buffer( &netNameLength2, sizeof( unsigned short )));
    buffers2.push_back( boost::asio::buffer( &name2[0], name2.length()));
    m_player->sendPacket( Packet::GameJoinedPacket, buffers2 );

    // the game is no longer open
    broadcastGameRemoved( game );
}


void PlayerHandler::handleLeaveGamePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleLeaveGamePacket [" << m_player->getId() << "]: received a leave game packet";

    SharedGame game = m_player->getGame();
    if ( !game ) {
        // no game, can't leave
        logWarning << "PlayerHandler::handleLeaveGamePacket [" << m_player->getId() << "]: no game in progress, nothing to leave";
        m_player->sendPacket( Packet::NoGamePacket );
        return;
    }

    // are we in a game?
    if ( game->hasStarted()) {
        logDebug << "PlayerHandler::handleLeaveGamePacket [" << m_player->getId() << "]: game in progress, informing other player";
        SharedPlayer player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
        if ( player1 ) {
            player1->sendPacket( Packet::GameEndedPacket );
            player1->clearGame();
            player1->setReadyToStart( false );
        }

        SharedPlayer player2 = PlayerManager::instance().getPlayer( game->getPlayerId2());
        if ( player2 ) {
            player2->sendPacket( Packet::GameEndedPacket );
            player2->clearGame();
            player2->setReadyToStart( false );
        }

        // set the game end time
        game->endGame();
    }
    else {
        // just our game, we've announced it
        m_player->clearGame();

        // only broadcast the remove if it is actively looking for players
        broadcastGameRemoved( game );
    }

    // fully remove the game
    GameManager::instance().removeGame( game );
}


void PlayerHandler::handleDataPacket (const SharedPacket &packet) {
    // is the peer set up?
    if ( !m_peer ) {
        if ( !findPeerPlayer()) {
            logError << "PlayerHandler::handleDataPacket [" << m_player->getId() << "]: no peer, can not handle data packet";
            return;
        }
    }

    std::vector<boost::asio::const_buffer> buffers;
    buffers.push_back( boost::asio::buffer( packet->getData(), packet->getDataLength()));
    m_peer->sendPacket( Packet::DataPacket, buffers );
}


void PlayerHandler::handleReadyToStartPacket (const SharedPacket &packet) {
    if ( !m_peer ) {
        if ( !findPeerPlayer()) {
            logError << "PlayerHandler::handleReadyToStartPacket [" << m_player->getId() << "]: no peer, can not handle ready to start packet";
            return;
        }
    }

    logDebug << "PlayerHandler::handleReadyToStartPacket [" << m_player->getId() << "]: player is now ready to start";
    m_player->setReadyToStart( true );

    // the below did crash with:
    /*
#0  0x0000000000507d64 in std::__shared_ptr<UdpHandler, (__gnu_cxx::_Lock_policy)2>::operator-> (this=0x80) at /usr/include/c++/4.8/bits/shared_ptr_base.h:915
#1  0x0000000000504932 in PlayerHandler::handleReadyToStartPacket (this=0x1b31610, packet=std::shared_ptr (count 1, weak 0) 0x1b32598) at /home/imperium/imperium-server/src/PlayerHandler.cpp:476
#2  0x0000000000501f6d in PlayerHandler::handlePacket (this=0x1b31610, error=...) at /home/imperium/imperium-server/src/PlayerHandler.cpp:167
#3  0x0000000000501de9 in PlayerHandler::handleHeader (this=0x1b31610, error=...) at /home/imperium/imperium-server/src/PlayerHandler.cpp:128
#4  0x000000000050d1ee in boost::_mfi::mf1<void, PlayerHandler, boost::system::error_code const&>::operator() (this=0x7ffc9908a888, p=0x1b31610, a1=...) at /usr/include/boost/bind/mem_fn_template.hpp:165
#5  0x000000000050bcd7 in boost::_bi::list2<boost::_bi::value<PlayerHandler*>, boost::arg<1> (*)()>::operator()<boost::_mfi::mf1<void, PlayerHandler, boost::system::error_code const&>, boost::_bi::list2<boost::system::error_code const&, 

when a player crashed after sending ready to start and another player just sent ready to start.
    */

    // check a lot in case there was a player disconnect
    if ( m_peer->isReadyToStart() && m_player && m_player->getGame() && m_player->getGame()->getUdpHandler()) {
        logDebug << "PlayerHandler::handleReadyToStartPacket [" << m_player->getId() << "]: both players ready to start, sending start UDP packets";
        m_player->getGame()->getUdpHandler()->sendStartPackets();
    }
}


void PlayerHandler::handleResourcePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleResourcePacket [" << m_player->getId() << "]: handling resource packet";
    unsigned int offset = 0;

    // get the resource name length
    unsigned short resourceNameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // invalid name?
    if ( resourceNameLength == 0 || resourceNameLength > 1024 ) {
        logWarning << "PlayerHandler::handleResourcePacket [" << m_player->getId() << "]: bad resource name length: " << resourceNameLength;
        m_player->sendPacket( Packet::InvalidResourcePacket );
        return;
    }

    // name length is ok, get the name
    std::string resourceName = packet->getString( offset, resourceNameLength );
    logDebug << "PlayerHandler::handleResourcePacket [" << m_player->getId() << "]: fetching resource: '" << resourceName << "'";

    std::string resource = ResourceLoader::loadResource( resourceName );
    if ( resource.length() == 0 ) {
        logWarning << "PlayerHandler::handleResourcePacket [" << m_player->getId() << "]: no data found for resource: " << resourceName;
        m_player->sendPacket( Packet::InvalidResourcePacket );
        return;
    }

    std::vector<boost::asio::const_buffer> buffers;

    // data length
    unsigned short netResourceLength = htons( resource.length());
    buffers.push_back( boost::asio::buffer( &netResourceLength, sizeof( unsigned short )));

    // raw data
    buffers.push_back( boost::asio::buffer( &resource[0], resource.length()));

    // send the packet
    m_player->sendPacket( Packet::ResourcePacket, buffers );
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


bool PlayerHandler::findPeerPlayer () {
    SharedPlayer tmpPlayer = PlayerManager::instance().getPlayer( m_player->getGame()->getPlayerId1());
    if ( tmpPlayer && tmpPlayer != m_player ) {
        m_peer = tmpPlayer;
    }
    else {
        tmpPlayer = PlayerManager::instance().getPlayer( m_player->getGame()->getPlayerId2());
        if ( tmpPlayer && tmpPlayer != m_player ) {
            m_peer = tmpPlayer;
        }
    }

    if ( !m_peer ) {
        logError << "PlayerHandler::findPeerPlayer [" << m_player->getId() << "]: no peer player found";
        return false;
    }

    return true;
}
