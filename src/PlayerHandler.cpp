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

PlayerHandler::PlayerHandler (boost::asio::io_service &io_service, unsigned short udpPort, unsigned int playerId)
        : m_tcpSocket( io_service ),
          m_udpSocket( io_service, udp::endpoint( udp::v4(), udpPort )), m_id(playerId),
          m_data( 0 ), m_loggedIn(false), m_readyToStart(false) {
}


PlayerHandler::~PlayerHandler () {
    m_tcpSocket.close();
    m_udpSocket.close();

    // do we have a game?
    if ( m_game ) {
        GameManager::instance().removeGame( m_game );

        // has the game started?
        if ( m_game->hasStarted()) {
            logDebug << "PlayerHandler::~PlayerHandler [" << m_id << "]: ending started game";

            PlayerHandler * player1 = PlayerManager::instance().getPlayer( m_game->getPlayerId1());
            if ( player1 ) {
                player1->sendPacket( Packet::GameEndedPacket );
                player1->clearGame();
            }

            PlayerHandler * player2 = PlayerManager::instance().getPlayer( m_game->getPlayerId2());
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


void PlayerHandler::start () {
    // read the first header
    readHeader();
}


bool PlayerHandler::sendPacket (Packet::TcpPacketType packetType) {
    logDebug << "PlayerHandler::sendPacket: sending packet [" << m_id << "]: " << Packet::getPacketName(packetType) << " to player: " << toString();

    // just send a header, we have no data
    return sendHeader( packetType, 0);
}


bool PlayerHandler::sendPacket (Packet::TcpPacketType packetType, const std::vector<boost::asio::const_buffer> &buffers) {
    logDebug << "PlayerHandler::sendPacket: sending packet [" << m_id << "]: " << Packet::getPacketName(packetType) << " to player: " << toString();

    // send a suitable header
    sendHeader( packetType, boost::asio::buffer_size( buffers ));

    try {
        // wrap the header as a buffer and send off
        boost::asio::write( m_tcpSocket, buffers );
        return true;
    }
    catch (std::exception &ex) {
        logError << "PlayerHandler::sendPacket: error sending packet [" << m_id << "]: " << ex.what();
        return false;
    }
}


std::string PlayerHandler::toString () const {
    std::stringstream ss;
    ss << "[PlayerHandler " << m_id << ']';
    return ss.str();
}


bool PlayerHandler::sendHeader (Packet::TcpPacketType packetType, unsigned short length) {
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

        // statistics
//        Statistics &stats = m_game->getStatistics( m_playerIndex );
//        stats.m_lastSentTcp = time(0);
//        stats.m_packetsSentTcp++;
//        stats.m_bytesSentTcp += length;

        //logDebug << "Player::sendHeader: sent header for packet: " << Packet::getPacketName(packetType); //", payload length: " << length;
    }
    catch (std::exception &ex) {
        logError << "PlayerHandler::sendHeader: error sending header [" << m_id << "]: " << ex.what();
        return false;
    }

    return true;
}


void PlayerHandler::readHeader () {
    std::vector<boost::asio::mutable_buffer> buffers;
    buffers.push_back( boost::asio::buffer( &m_packetType, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &m_dataLength, sizeof( unsigned short )));

    //logDebug << "PlayerHandler::readHeader: reading header";

    boost::asio::async_read( m_tcpSocket, buffers, boost::bind( &PlayerHandler::handleHeader, this, boost::asio::placeholders::error ));
}


void PlayerHandler::handleHeader (const boost::system::error_code &error) {
    if ( error ) {
        if ( error == boost::asio::error::eof ) {
            // connection closed
            logDebug << "PlayerHandler::handleHeader [" << m_id << "]: connection closed";
        }
        else {
            logError << "PlayerHandler::handleHeader [" << m_id << "]: error reading header: " << error.message();
        }

        terminated( this );
        return;
    }

    // convert to host order
    m_packetType = ntohs( m_packetType );
    m_dataLength = ntohs( m_dataLength );

    // precautions
    if ( !Packet::isValidPacket( m_packetType )) {
        logError << "PlayerHandler::handleHeader [" << m_id << "]: invalid packet: " << m_packetType << ", closing connection";
        terminated( this );
        return;
    }

    //logDebug << "PlayerHandler::handleHeader [" << m_id << "]: received header for packet: " << Packet::getPacketName( m_packetType ) <<
    //", data length: " << m_dataLength;

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
            logDebug << "PlayerHandler::handleHeader [" << m_id << "]: connection closed";
        }
        else {
            logError << "PlayerHandler::handlePacket [" << m_id << "]: error reading packet data: " << error.message();
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
            logError << "PlayerHandler::handlePacket [" << m_id << "]: unknown packet type: " << (int) packet->getType();
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
        logWarning << "PlayerHandler::handleLoginPacket [" << m_id << "]: server is full, failing login";
        sendPacket( Packet::ServerFullPacket );
        return;
    }

    unsigned int offset = 0;

    // get the protocol version
    unsigned short protocolVersion = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // wrong protocol version?
    if ( protocolVersion != s_protocolVersion ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_id << "]: bad protocol: " << protocolVersion << ", we support: " <<
        s_protocolVersion;
        sendPacket( Packet::InvalidProtocolPacket );
        return;
    }

    // already logged in?
    if ( m_loggedIn ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_id << "]: has already logged in as: " << m_name << ", failing login";
        sendPacket( Packet::AlreadyLoggedInPacket );
        return;
    }

    // get the name length
    unsigned short nameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    // invalid name?
    if ( nameLength == 0 || nameLength > 50 ) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_id << "]: bad name length: " << nameLength << ", failing login";
        sendPacket( Packet::InvalidNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string name = packet->getString( offset, nameLength );

    // name already taken?
    if ( PlayerManager::instance().isNameTaken( name )) {
        logWarning << "PlayerHandler::handleLoginPacket [" << m_id << "]: name '" << name << "' is already taken, failing login";
        sendPacket( Packet::NameTakenPacket );
        return;
    }

    // now our player has logged in
    m_name = name;
    m_loggedIn = true;

    logDebug << "PlayerHandler::handleLoginPacket [" << m_id << "]: login from player: " << m_name;

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
        PlayerHandler * owner = PlayerManager::instance().getPlayer( game->getPlayerId1());
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
        logDebug << "PlayerHandler::handleLoginPacket [" << m_id << "]: sending game: " << game->toString() << " to player: " << m_name;
        sendPacket( Packet::GameAddedPacket, buffers );
    }
}


void PlayerHandler::handleAnnounceGamePacket (const SharedPacket &packet) {
    // get the announced game id
    unsigned short announcedId = packet->getUnsignedShort( 0 );

    logDebug << "PlayerHandler::handleAnnounceGamePacket [" << m_id << "]: received an announcement for game: " << announcedId;

    // do we have an old game?
    if ( m_game ) {
        logWarning << "PlayerHandler::handleAnnounceGamePacket [" << m_id << "]: old game already announced: " << m_game->getScenarioId() <<
        ", can not announce new";
        sendPacket( Packet::AlreadyAnnouncedPacket );
        return;
    }

    // create the new game, we're player 1
    m_game = GameManager::instance().createGame( announcedId, m_id );

    // all ok, send a response with the announced game id
    std::vector<boost::asio::const_buffer> buffers;
    unsigned int netGameId = htonl( m_game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));
    sendPacket( Packet::AnnounceOkPacket, buffers );

    // send out the game to everyone
    broadcastGameAdded( m_game );
}


void PlayerHandler::handleJoinGamePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: received a join game packet";

    // do we have a game?
    if ( m_game ) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: already have a game: " << m_game->getScenarioId() << ", can not join";
        sendPacket( Packet::AlreadyHasGamePacket );
        return;
    }

    // get the game id
    unsigned int gameId = packet->getUnsignedInt( 0 );

    // do we have such a game?
    SharedGame game = GameManager::instance().getGame( gameId );
    if ( !game ) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: no game with id: " << gameId;
        sendPacket( Packet::InvalidGamePacket );
        return;
    }

    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: player: " << m_name << " wants to join game: " <<
    game->toString();

    // has the game already started?
    if ( game->hasStarted()) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: game: " << game->toString() << " has already started, can not join";
        sendPacket( Packet::GameFullPacket );
        return;
    }

    // find the first, owning player
    PlayerHandler * player1 = PlayerManager::instance().getPlayer( game->getPlayerId1());
    if ( !player1 ) {
        logWarning << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: owner player not found for game: " << game->toString();
        sendPacket( Packet::InvalidGamePacket );
        return;
    }

    // game, meet player, we're player 2
    game->setPlayerId2( m_id );
    m_game = game;

    // create the UDP handler
    boost::system::error_code ec1, ec2;
    boost::asio::ip::tcp::endpoint ep1 = player1->getTcpSocket().remote_endpoint( ec1 );
    boost::asio::ip::tcp::endpoint ep2 = m_tcpSocket.remote_endpoint( ec2 );

    if ( ec1 ) {
        logError << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: failed to get player 1 TCP endpoint" << ec1.message();
        return;
    }
    if ( ec2 ) {
        logError << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: failed to get player 2 TCP endpoint: " << ec2.message();
        return;
    }

    logDebug << "PlayerHandler::handleJoinGamePacket [" << m_id << "]: endpoint 1: " << ep1.address() << ", endpoint 2: " << ep2.address();

    // set up the UDP handler
    SharedUdpHandler udpHandler = std::make_shared<UdpHandler>( player1->getUdpSocket(), m_udpSocket, ep1.address(), ep2.address(),
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


void PlayerHandler::handleLeaveGamePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleLeaveGamePacket [" << m_id << "]: received a leave game packet";

    if ( !m_game ) {
        // no game, can't leave
        logWarning << "PlayerHandler::handleLeaveGamePacket [" << m_id << "]: no game in progress, nothing to leave";
        sendPacket( Packet::NoGamePacket );
        return;
    }

    // set the game end time
    m_game->endGame();

    // first fully remove the game
    GameManager::instance().removeGame( m_game );

    // are we in a game?
    if ( m_game->hasStarted()) {
        logDebug << "PlayerHandler::handleLeaveGamePacket [" << m_id << "]: game in progress, informing other player";
        PlayerHandler * peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
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


void PlayerHandler::handleDataPacket (const SharedPacket &packet) {
    // find the peer player
    PlayerHandler * peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
    if ( !peer ) {
        logError << "PlayerHandler::handleDataPacket [" << m_id << "]: peer not found, can not handle data packet";
        return;
    }

    std::vector<boost::asio::const_buffer> buffers;
    buffers.push_back( boost::asio::buffer( packet->getData(), packet->getDataLength()));
    peer->sendPacket( Packet::DataPacket, buffers );
}


void PlayerHandler::handleReadyToStartPacket (const SharedPacket &packet) {
    // find the peer player
    PlayerHandler * peer = PlayerManager::instance().getPlayer( m_game->getPeerId( m_id ));
    if ( !peer ) {
        logError << "PlayerHandler::handleReadyToStartPacket [" << m_id << "]: no peer, can not handle ready to start packet";
        return;
    }

    logDebug << "PlayerHandler::handleReadyToStartPacket [" << m_id << "]: player is now ready to start";
    m_readyToStart = true;

    logDebug << "PlayerHandler::handleReadyToStartPacket [" << m_id << "]: " << peer->isReadyToStart() << " " << m_game;

    // check a lot in case there was a player disconnect
    if ( peer->isReadyToStart() && m_game && m_game->getUdpHandler()) {
        logDebug << "PlayerHandler::handleReadyToStartPacket [" << m_id << "]: both players ready to start, sending start UDP packets";
        m_game->getUdpHandler()->sendStartPackets();
    }
}


void PlayerHandler::handleResourcePacket (const SharedPacket &packet) {
    logDebug << "PlayerHandler::handleResourcePacket [" << m_id << "]: handling resource packet";
    unsigned int offset = 0;

    // get the resource name length
    unsigned short resourceNameLength = packet->getUnsignedShort( offset );
    offset += sizeof( unsigned short );

    std::vector<boost::asio::const_buffer> buffers;

    // invalid name?
    if ( resourceNameLength == 0 || resourceNameLength > 1024 ) {
        logWarning << "PlayerHandler::handleResourcePacket [" << m_id << "]: bad resource name length: " << resourceNameLength;
        sendPacket( Packet::InvalidResourceNamePacket );
        return;
    }

    // name length is ok, get the name
    std::string resourceName = packet->getString( offset, resourceNameLength );
    logDebug << "PlayerHandler::handleResourcePacket [" << m_id << "]: fetching resource: '" << resourceName << "'";

    // always add the name first
    unsigned short netNameLength = htons( resourceNameLength );
    buffers.push_back( boost::asio::buffer( &netNameLength, sizeof( unsigned short )));
    buffers.push_back( boost::asio::buffer( &resourceName[0], resourceName.length()));

    std::string resource = ResourceLoader::loadResource( resourceName );
    if ( resource.length() == 0 ) {
        logWarning << "PlayerHandler::handleResourcePacket [" << m_id << "]: no data found for resource: " << resourceName;
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

    logDebug << "PlayerHandler::handleResourcePacket [" << m_id << "]: resource: '" << resourceName << "' is " << totalLength
             << " bytes, sending in " << (int)packetCount << " packets";

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
        //logDebug << "PlayerHandler::handleResourcePacket [" << m_id << "]: sending " << packetSize << " bytes";

        // raw data
        buffers.push_back( boost::asio::buffer( &resource[offset], packetSize));

        // send the packet
        sendPacket( Packet::ResourcePacket, buffers );

        packetIndex++;
        offset += packetSize;
    }
}


void PlayerHandler::broadcastGameAdded (const SharedGame &game) {
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


void PlayerHandler::broadcastGameRemoved (const SharedGame &game) {
    std::vector<boost::asio::const_buffer> buffers;

    // the id of the removed game
    unsigned int netGameId = htonl( game->getGameId());
    buffers.push_back( boost::asio::buffer( &netGameId, sizeof( unsigned int )));

    PlayerManager::instance().broadcastPacket( Packet::GameRemovedPacket, buffers );
}
