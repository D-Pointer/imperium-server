# imperium-server
Network server for Imperium.

## Protocol

### Header
Each packet contains two mandatory fields:
* packet length (unsigned short)
* packet type (unsigned short)

The packet length contains the length excluding the length field itself. A minimal packet that only contains a packet type will thus have a length of 2, i.e. enough to fit the packet type. Any packet specific extra data comes after the header.

---

### Info packet
The Info packet tells the server who the player is and what name he/she will go by. This should be the first packet sent by any client. Contents:

* client version (unsigned int). A coded version number where 1.2.3 becomes 102030. Can be used to validate that the client is suitably new.

#### Reply
* OkPacket
* ErrorPacket

---

### Announce packet
The announce packet announces a game to other players. One of the other players can then choose to join that gane.

* scenario id (unsigned short)
* tag (unsigned short)

The scenario id is the id of the scenario that the player announces that he/she will host. The tag is an id for the announcement. 

#### Reply
* OkPacket if the game was announced ok
* ErrorPacket if the game could not be announced, i.e. the player already has announced or joined another game.

---

### Subscribe packet
The subscribe packet indicates that the client wants to receive updates to games, i.e. announced, left and started games.

* tag (unsigned short)

#### Reply
* OkPacket

---

### Unubscribe packet
The unsubscribe packet indicates that the client no longer wants to receive updates to games.

* tag (unsigned short)

#### Reply
* OkPacket

---

### Ok packet
The Ok packet is only sent by the server in response to some other packet. All packets that have a tag will always receive an Ok or Error packet that contains the tag. The Ok packet means that original packet sent by the client was successfully executed. 

---

### Error packet
This is similar to the Ok packet but means the action failed. It also contains a tag identifying the original packet to which the failure is related.


## UDP data
There is no custom UDP protocol. Everything sent to the server will simply be sent as-is to the other player. The only exception to this is the first packet sent by both player which will be discarded. The first packet is used by the server to get the address and port of the client's sockets. Until both players have sent one packet all other data is discarded. Once both players have sent one dummy packet (the contents is irrelevant) all further packets are just relayed.
