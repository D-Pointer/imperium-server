#ifndef DEFINITIONS_HPP
#define DEFINITIONS_HPP

static const int s_protocolVersion = 0;

// max concurrent players
static const int s_maxPlayers = 5;

// max time in seconds that the players can idle. Longer TCP idle as a player can connect, announce a game and then
// sit and wait for players
const unsigned int maxTcpSeconds = 60;
const unsigned int maxUdpSeconds = 10;

#endif
