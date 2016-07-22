#include <sstream>

#include <boost/lexical_cast.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

#include "Player.hpp"
#include "ResourceLoader.hpp"
#include "GameManager.hpp"
#include "PlayerManager.hpp"
#include "Definitions.hpp"
#include "Log.hpp"

using boost::asio::ip::udp;

Player::Player (boost::asio::io_service &io_service, unsigned short udpPort, unsigned int playerId)
        : m_tcpSocket( io_service ),
          m_udpSocket( io_service, udp::endpoint( udp::v4(), udpPort )), m_id( playerId ),
          m_data( 0 ), m_statistics( new Statistics ), m_loggedIn( false ), m_readyToStart( false ) {
    m_statistics->m_connected = time( 0 );
}


Player::~Player () {
    m_tcpSocket.close();
    m_udpSocket.close();

    // we've now disconnected
    m_statistics->m_connected = time( 0 );

    // do we have a game?
    if ( m_game ) {
        GameManager::instance().removeGame( m_game );

        // has the game started?
        if ( m_game->hasStarted()) {
            logDebug << logData("~PlayerHandler") << "ending started game";

            SharedPlayer player1 = PlayerManager::instance().getPlayer( m_game->getPlayerId1());
            if ( player1 ) {
                player1->sendPacket( Packet::GameEndedPacket );
                player1->clearGame();
            }

            SharedPlayer player2 = PlayerManager::instance().getPlayer( m_game->getPlayerId2());
            if ( player2 ) {
                player2->sendPacket( Packet::GameEndedPacket );
                player2->clearGame();
            }
        }
        else {
            // not started, so it was still looking for players, but not anymore
            broadcastGameRemoved( m_game );
        }
    }
}


void Player::start () {
    // read the first header
    readHeader();
}


void Player::stop () {
    logDebug << logData( "stop" ) << "stopping session";

    boost::system::error_code error;
    m_tcpSocket.close( error );

    // do we have a game in progress?
    if ( m_game ) {
        // end the game nicely
        m_game->endGame();
    }
    else {
        // no game, just close the socket
        m_udpSocket.close( error );
    }
}


bool Player::sendPacket (Packet::TcpPacketType packetType) {
    logDebug << logData( "sendPacket" ) << "sending packet: " << Packet::getPacketName( packetType );

    // statistics
    m_statistics->m_lastSentTcp = time( 0 );
    m_statistics->m_packetsSentTcp++;
    m_statistics->m_bytesSentTcp += 2 * sizeof( unsigned short );

    // just send a header, we have no data
    return sendHeader( packetType, 0 );
}


bool Player::sendPacket (Packet::TcpPacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    logDebug << logData( "sendPacket" ) << "sending packet: " << Packet::getPacketName( packetType );

    size_t packetSize = boost::asio::buffer_size( buffers );

    // statistics
    m_statistics->m_lastSentTcp = time( 0 );
    m_statistics->m_packetsSentTcp++;
    m_statistics->m_bytesSentTcp += 2 * sizeof( unsigned short ) + packetSize;

    // send a suitable header
    sendHeader( packetType, packetSize );

    try {
        // wrap the header as a buffer and send off
        boost::asio::write( m_tcpSocket, buffers );
        return true;
    }
    catch (std::exception &ex) {
        logError << logData( "sendPacket" ) << "error sending packet: " << ex.what();
        return false;
    }
}


bool Player::sendHeader (Packet::TcpPacketType packetType, unsigned short length) {
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
        boost::asio::write( m_tcpSocket, buffers );

        //logDebug << "Player::sendHeader: sent header for packet: " << Packet::getPacketName(packetType); //", payload length: " << length;
    }
    catch (std::exception &ex) {
        logError << logData( "sendHeader" ) << "error sending header: " << ex.what();
        return false;
    }

    return true;
}


void Player::readHeader () {
    std::vector<boost::asio::mutable_buffer> buffers;
    buffers.push_back( boost::asio::buffer( &m_packetType, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &m_dataLength, sizeof( unsigned short )));

    //logDebug << logData( "readHeader" ) << "readHeader: reading header";

    boost::asio::async_read( m_tcpSocket, buffers, boost::bind( &Player::handleHeader, this, boost::asio::placeholders::error ));
}


void Player::handleHeader (const boost::system::error_code &error) {
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << logData( "handleHeader" ) << "connection closed";
        }
        else {
            logError << logData( "handleHeader" ) << "error reading header: " << error.message();
        }

        terminate();
        return;
    }

    // convert to host order
    m_packetType = ntohs( m_packetType );
    m_dataLength = ntohs( m_dataLength );

    // precautions
    if ( !Packet::isValidPacket( m_packetType )) {
        logError << logData( "handleHeader" ) << "invalid packet: " << m_packetType << ", closing connection";
        terminate();
        return;
    }

    //logDebug << logData( "handleHeader" ) << "handleHeader [" << m_id << "]: received header for packet: " << Packet::getPacketName( m_packetType ) <<
    //", data length: " << m_dataLength;

    // read the data, if there is anything to read
    if ( m_dataLength > 0 ) {
        m_data = new unsigned char[m_dataLength];

        // read the data
        boost::asio::async_read( m_tcpSocket, boost::asio::buffer( m_data, m_dataLength ),
                                 boost::bind( &Player::handlePacket, this, boost::asio::placeholders::error ));
    }
    else {
        // no data for this packet, handle it right away
        handlePacket( error );
    }
}


void Player::handlePacket (const boost::system::error_code &error) {
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << logData( "handlePacket" ) << "connection closed";
        }
        else {
            logError << logData( "handlePacket" ) << "error reading packet data: " << error.message();
        }

        terminate();
        return;
    }

    // create a packet
    SharedPacket packet = std::make_shared<Packet>((Packet::TcpPacketType) m_packetType, m_data, m_dataLength );

    // statistics
    m_statistics->m_lastReceivedTcp = time( 0 );
    m_statistics->m_packetsReceivedTcp++;
    m_statistics->m_bytesReceivedTcp += sizeof( unsigned short ) * 2 + m_dataLength;

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

        case Packet::KeepAlivePacket:
            handleKeepAlivePacket( packet );
            break;

        default:
            logError << logData( "handlePacket" ) << "unknown packet type: " << (int) packet->getType();
            break;
    }

    // the packet manages the data now
    m_data = 0;

    // back to reading the header
    readHeader();
}


void Player::handleLoginPacket (const SharedPacket &packet) {
    // too many players?
    if ( PlayerManager::instance().getPlayerCount() >= s_maxPlayers ) {
        logWarning << logData( "handleLoginPacket" ) << "server is full, failing login";
        sendPacket( Packet::ServerFullPacket );
        return;
    }

    unsigned int offset = 0;

    // get the protocol version
    unsigned short protocolVersion = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // wrong protocol version?
    if ( protocolVersion != s_protocolVersion ) {
        logWarning << logData( "handleLoginPacket" ) << "bad protocol: " << protocolVersion << ", we support: " <<
                   s_protocolVersion;
        sendPacket( Packet::InvalidProtocolPacket );
        return;
    }

    // already logged in?
    if ( m_loggedIn ) {
        logWarning << logData( "handleLoginPacket" ) << "has already logged in as: " << m_name << ", failing login";
        sendPacket( Packet::AlreadyLoggedInPacket );
        return;
    }

    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // invalid name?
    if ( nameLength == 0 || nameLength > 50 ) {
        logWarning << logData( "handleLoginPacket" ) << "bad name length: " << nameLength << ", failing login";
        sendPacket( Packet::InvalidNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string name = packet->getString( offset, nameLength );

    // name already taken?
    if ( PlayerManager::instance().isNameTaken( name )) {
        logWarning << logData( "handleLoginPacket" ) << "name '" << name << "' is already taken, failing login";
        sendPacket( Packet::NameTakenPacket );
        return;
    }

    // now our player has logged in
    m_name = name;
    m_statistics->m_name = name;
    m_loggedIn = true;

    logDebug << logData( "handleLoginPacket" ) << "login from player: " << m_name;

    // player login ok
    sendPacket( Packet::LoginOkPacket );

    // send all current games as "game added" packets
    for ( auto game : GameManager::instance().getAllGames()) {
        std::vector<boost::asio::const_buffer> buffers;

        // the id of the added game
        unsigned int netGameId = htonl( game->getGameId());
        buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

        // the id of the scenario
        unsigned short netScenarioId = htons( game->getScenarioId());
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
        logDebug << logData( "" ) << "sending game: " << game->toString() << " to player: " << m_name;
        sendPacket( Packet::GameAddedPacket, buffers );
    }
}


void Player::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    logDebug << logData( "handleAnnounceGamePacket" ) << "received an announcement for game: " << announcedId;

    // do we have an old game?
    if ( m_game ) {
        logWarning << logData( "handleAnnounceGamePacket" ) << "old game already announced: " << m_game->getScenarioId() <<
                   ", can not announce new";
        sendPacket( Packet::AlreadyAnnouncedPacket );
        return;
    }

    // create the new game, we're player 1
    m_game = GameManager::instance().createGame( announcedId, m_id, m_name );
    m_game->setStatistics( 0, m_statistics );

    // all ok, send a response with the announced game id
    std::vector<boost::asio::const_buffer> buffers;
    unsigned int netGameId = htonl( m_game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));
    sendPacket( Packet::AnnounceOkPacket, buffers );

    // send out the game to everyone
    broadcastGameAdded( m_game );
}


void Player::handleJoinGamePacket (const SharedPacket &packet) {
    logDebug << logData( "handleJoinGamePacket" ) << "received a join game packet";

    // do we have a game?
    if ( m_game ) {
        logWarning << logData( "handleJoinGamePacket" ) << "already have a game: " << m_game->getScenarioId() << ", can not join";
        sendPacket( Packet::AlreadyHasGamePacket );
        return;
    }

    // get the game id
    unsigned int gameId = packet->getUnsignedInt( 0 );

    // do we have such a game?
    SharedGame game = GameManager::instance().getGame( gameId );
    if ( !game ) {
        logWarning << logData( "handleJoinGamePacket" ) << "no game with id: " << gameId;
        sendPacket( Packet::InvalidGamePacket );
        return;
    }

    logDebug << logData( "handleJoinGamePacket" ) << "player: " << m_name << " wants to join game: " <<
             game->toString();

    // has the game already started?
    if ( game->hasStarted()) {
        logWarning << logData( "handleJoinGamePacket" ) << "game: " << game->toString() << " has already started, can not join";
        sendPacket( Packet::GameFullPacket );
        return;
    }

    // find the first, owning player
    SharedPlayer player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
    if ( !player1 ) {
        logWarning << logData( "handleJoinGamePacket" ) << "handleJoinGamePacket [" << m_id << "]: owner player not found for game: " << game->toString();
        sendPacket( Packet::InvalidGamePacket );
        return;
    }

    // game, meet player, we're player 2
    game->setPlayer2Data( m_id, m_name );
    m_game = game;
    m_game->setStatistics( 1, m_statistics );

    // create the UDP handler
    boost::system::error_code ec1, ec2;
    boost::asio::ip::tcp::endpoint ep1 = player1->getTcpSocket().remote_endpoint( ec1 );
    boost::asio::ip::tcp::endpoint ep2 = m_tcpSocket.remote_endpoint( ec2 );

    if ( ec1 ) {
        logError << logData( "handleJoinGamePacket" ) << "failed to get player 1 TCP endpoint" << ec1.message();
        return;
    }
    if ( ec2 ) {
        logError << logData( "handleJoinGamePacket" ) << "failed to get player 2 TCP endpoint: " << ec2.message();
        return;
    }

    logDebug << logData( "handleJoinGamePacket" ) << "endpoint 1: " << ep1.address() << ", endpoint 2: " << ep2.address();

    // set up the UDP handler
    SharedUdpHandler udpHandler = std::make_shared<UdpHandler>( m_game->getGameId(), player1->getUdpSocket(), m_udpSocket, ep1.address(), ep2.address(),
                                                                game->getStatistics( 0 ), game->getStatistics( 1 ));
    m_game->setUdpHandler( udpHandler );
    udpHandler->start();

    // send to both players that the game has been joined
    std::vector<boost::asio::const_buffer> buffers1;

    unsigned short netPort1 = htons( m_udpSocket.local_endpoint().port());
    buffers1.push_back( boost::asio::buffer( &netPort1, sizeof( unsigned short )));

    unsigned short netNameLength1 = htons( m_name.length());
    buffers1.push_back( boost::asio::buffer( &netNameLength1, sizeof( unsigned short )));
    buffers1.push_back( boost::asio::buffer( &m_name[0], m_name.length()));
    player1->sendPacket( Packet::GameJoinedPacket, buffers1 );

    std::vector<boost::asio::const_buffer> buffers2;

    // CRASH
    unsigned short netPort2 = htons( player1->getUdpSocket().local_endpoint().port());
    buffers2.push_back( boost::asio::buffer( &netPort2, sizeof( unsigned short )));

    std::string name2 = player1->getName();
    unsigned short netNameLength2 = htons( name2.length());
    buffers2.push_back( boost::asio::buffer( &netNameLength2, sizeof( unsigned short )));
    buffers2.push_back( boost::asio::buffer( &name2[0], name2.length()));
    sendPacket( Packet::GameJoinedPacket, buffers2 );

    // the game is no longer open
    broadcastGameRemoved( game );
}


void Player::handleLeaveGamePacket (const SharedPacket &packet) {
    logDebug << logData( "handleLeaveGamePacket" ) << "received a leave game packet";

    if ( !m_game ) {
        // no game, can't leave
        logWarning << logData( "handleLeaveGamePacket" ) << "no game in progress, nothing to leave";
        sendPacket( Packet::NoGamePacket );
        return;
    }

    // set the game end time
    m_game->endGame();

    // first fully remove the game
    GameManager::instance().removeGame( m_game );

    // are we in a game?
    if ( m_game->hasStarted()) {
        logDebug << logData( "handleLeaveGamePacket" ) << "game in progress, informing other player";
        SharedPlayer peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
        if ( peer ) {
            peer->sendPacket( Packet::GameEndedPacket );
            peer->clearGame();
        }

        // now clear our data
        sendPacket( Packet::GameEndedPacket );
        clearGame();
    }
    else {
        // it has not started, so it's looking for players. broadcast the removal
        broadcastGameRemoved( m_game );
        clearGame();
    }
}


void Player::handleDataPacket (const SharedPacket &packet) {
    // find the peer player
    SharedPlayer peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
    if ( !peer ) {
        logError << logData( "handleDataPacket" ) << "peer not found, can not handle data packet";
        return;
    }

    std::vector<boost::asio::const_buffer> buffers;
    buffers.push_back( boost::asio::buffer( packet->getData(), packet->getDataLength()));
    peer->sendPacket( Packet::DataPacket, buffers );
}


void Player::handleReadyToStartPacket (const SharedPacket &packet) {
    // find the peer player
    SharedPlayer peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
    if ( !peer ) {
        logError << logData( "handleReadyToStartPacket" ) << "no peer, can not handle ready to start packet";
        return;
    }

    logDebug << logData( "handleReadyToStartPacket" ) << "player is now ready to start";
    m_readyToStart = true;

    // check a lot in case there was a player disconnect
    if ( peer->isReadyToStart() && m_game && m_game->getUdpHandler()) {
        logDebug << logData( "handleReadyToStartPacket" ) << "both players ready to start, sending start UDP packets";
        m_game->getUdpHandler()->sendStartPackets();
    }
}


void Player::handleResourcePacket (const SharedPacket &packet) {
    logDebug << logData( "handleResourcePacket" ) << "handling resource packet";
    unsigned int offset = 0;

    // get the resource name length
    unsigned short resourceNameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    std::vector<boost::asio::const_buffer> buffers;

    // invalid name?
    if ( resourceNameLength == 0 || resourceNameLength > 1024 ) {
        logWarning << logData( "handleResourcePacket" ) << "bad resource name length: " << resourceNameLength;
        sendPacket( Packet::InvalidResourceNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string resourceName = packet->getString( offset, resourceNameLength );
    logDebug << logData( "handleResourcePacket" ) << "fetching resource: '" << resourceName << "'";

    // always add the name first
    unsigned short netNameLength = htons( resourceNameLength );
    buffers.push_back( boost::asio::buffer( &netNameLength, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &resourceName[0], resourceName.length()));

    std::string resource = ResourceLoader::loadResource( resourceName );
    if ( resource.length() == 0 ) {
        logWarning << logData( "handleResourcePacket" ) << "no data found for resource: " << resourceName;
        sendPacket( Packet::InvalidResourcePacket, buffers );
        return;
    }

    offset = 0;
    unsigned char packetIndex = 0;

    // total resource length
    unsigned int totalLength = resource.length();
    unsigned int netTotalLength = htonl( totalLength );

    // the number of packets we will need to send
    unsigned char packetCount = totalLength / 65000;
    if ( packetCount * 65000 < totalLength ) {
        packetCount++;
    }

    logDebug << logData( "handleResourcePacket" ) << "resource: '" << resourceName << "' is " << totalLength << " bytes, sending in " << (int) packetCount << " packets";

    // send all packets
    while ( offset < totalLength ) {
        // clear the buffers between sends so that we start with fresh data
        buffers.clear();
        buffers.push_back( boost::asio::buffer( &netNameLength, sizeof( unsigned short )));
        buffers.push_back( boost::asio::buffer( &resourceName[0], resourceName.length()));
        buffers.push_back( boost::asio::buffer( &netTotalLength, sizeof( unsigned int )));
        buffers.push_back( boost::asio::buffer( &packetIndex, sizeof( unsigned char )));
        buffers.push_back( boost::asio::buffer( &packetCount, sizeof( unsigned char )));

        // how much to send?
        unsigned short packetSize = offset + 65000 <= totalLength ? 65000 : totalLength - offset;
        unsigned short netPacketSize = htons( packetSize );
        buffers.push_back( boost::asio::buffer( &netPacketSize, sizeof( unsigned short )));
        //logDebug << logData( "handleResourcePacket" ) << "handleResourcePacket [" << m_id << "]: sending " << packetSize << " bytes";

        // raw data
        buffers.push_back( boost::asio::buffer( &resource[offset], packetSize ));

        // send the packet
        sendPacket( Packet::ResourcePacket, buffers );

        packetIndex++;
        offset += packetSize;
    }
}


void Player::handleKeepAlivePacket (const SharedPacket &packet) {
    logDebug << logData( "handleKeepAlivePacket" ) << "got keepalive";
}


void Player::broadcastGameAdded (const SharedGame &game) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the added game
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    // the id of the scenario
    unsigned short netScenarioId = htons( game->getScenarioId());
    buffers.push_back( boost::asio::buffer( &netScenarioId, sizeof( unsigned short )));

    // name length
    unsigned short netnameLength = htons( m_name.length());
    buffers.push_back( boost::asio::buffer( &netnameLength, sizeof( unsigned short )));

    // raw name
    buffers.push_back( boost::asio::buffer( &m_name[0], m_name.length()));

    // send to everyone
    PlayerManager::instance().broadcastPacket( Packet::GameAddedPacket, buffers );
}


void Player::broadcastGameRemoved (const SharedGame &game) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the removed game
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    PlayerManager::instance().broadcastPacket( Packet::GameRemovedPacket, buffers );
}


void Player::terminate () {
    logDebug << logData( "terminate" ) << "terminating";
    SharedPlayer self = shared_from_this();
    PlayerManager::instance().removePlayer( SharedPlayer( self ));
}


std::string Player::logData (const std::string &method) {
    std::stringstream ss;
    ss << "PlayerHandler::" << "" << method << " [";
    if ( m_game ) {
        ss << m_game->getGameId() << ".";
    }
    ss << m_id << "]: ";
    return ss.str();
}
