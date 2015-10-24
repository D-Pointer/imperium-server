# imperium-server
Network server for Imperium.

## Protocol

### Header
Each packet contains two mandatory fields:
* packet length (unsigned short)
* packet type (unsigned short)

The packet length contains the length excluding the length field itself. A minimal packet that only contains a packet type will thus have a length of 2, i.e. enough to fit the packet type. Any packet specific extra data comes after the header.

### Announce packet
The announce packet announces a game to other players. One of the other players can then choose to join that gane.

* scenario id (unsigned short)
* tag (unsigned short)

The scenario id is the id of the scenario that the player announces that he/she will host. The tag is an id for the announcement. The reply is an Ok or Error packet with the received tag.


### Subscribe packet
The subscribe packet indicates that the client wants to receive updates to games, i.e. announced, left and started games.

* tag (unsigned short)

The reply is always an Ok packet with the received tag.


### Unubscribe packet
The unsubscribe packet indicates that the client no longer wants to receive updates to games.

* tag (unsigned short)

The reply is always an Ok packet with the received tag.

