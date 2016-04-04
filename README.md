# imperium-server
Network server for Imperium. It can also be used for any other game that has two players.

## Installation

Installing the server requires a few libs and CMake.

### Dependencies

* CMake >= 2.8
* Boost >= 1.55 (http://www.boost.org/)
* Log4Cpp 1.1.1 (http://log4cpp.sourceforge.net/)

### Compiling

````
% cd imperium-server
% mkdir build
% cd build
% cmake ..
% make
````

The final binary is `imperium-server` in the `build` directory. You may need to add include paths for your dependencies if they are not installed in standard
directories. Example:

````
% cmake -DCMAKE_CXX_FLAGS="-I/opt/boost/include" ..
````

## Concepts
The idea behind the server.

## Running

To run the server start it with a path to a directory used to run it in, the IP address to bind to and a TCP port. Due
to a bug in Boost Filesystem the `LC_ALL` environment variable must be set to `C`:

````
% export LC_ALL=C
% ./imperium-server /path/to/run/dir 0.0.0.0 11000
````

The path is where the server saves log files and various statistics.

### Running with `stunnel`

If you want to secure the server a bit and use SSL/TLS for the TCP data you can put `stunnel` in front of it.
In that case you want to bind to an internal IP address only and have `stunnel` forward traffic:

````
% export LC_ALL=C
% ./imperium-server /path/to/run/dir 127.0.0.1 11000
````

A minimal `stunnel` config file that works is something like:

````
; certs
cert=/etc/.../fullchain.pem
key=/etc/.../privkey.pem

; disable support for insecure SSLv2 protocol
options = NO_SSLv2

[imperium-server]
accept  = 11000
connect = 11001
````

In this case the server uses a different port than the one open towards the Internet as `stunnel`
seems to reserve it. Certificates can be had from various place, but I've used
[Let's Encrypt](https://letsencrypt.org/) to get a free certificate.

---

## Protocol

### Header
Each packet contains two mandatory fields:
* packet type (`unsigned short`)
* packet length (`unsigned short`)

The packet length contains the length of the payload. If the packet type does not require any payload this will be 0.
Many packets are simply informational in their nature, i.e. they contain no extra data apart
from the packet type, such as **ServerFullPacket**.

## Packets

### Login
Sent by clients.

* name length (`unsigned short`)
* name (name length of characters), not null terminated

Responses:

* **ServerFullPacket**, server full
* **InvalidNamePacket**, invalid name. The name must be 1 to 50 characters long.
* **NameTakenPacket**, name taken by another player.
* **LoginOkPacket** packet.

### Login ok
Sent by the server as a response to a **Login** packet and indicates that the player was logged in ok and can now
announce games or join existing games.

### Invalid protocol
Sent by the server as a response to a **Login** packet and indicates that the game and the server use different protocols and
can not communicate.

### Invalid name
Sent by the server as a response to a **Login** packet and indicates that the name given by the player is invalid. It may
be too long (the limit is 50 characters), be null or it contains forbidden words. The player can log in again using a
different name.

### Name taken
Sent by the server as a response to a **Login** packet and indicates that the name has already been taken by another player.
The player needs to choose another name and log in again.

### Server full
Sent by the server as a response to a **Login** packet and indicates that the server is currently full and does nto accept any more
players. The player can try to log in again later.

### Announce
Sent by players when they announce a game that some other player can join.

* game id (`unsigned short`). This is a game specific id that the server does not interpret in any way.

Responses:

* **AlreadyAnnouncedPacket** if the player has already announced a game. The old game must be
left before a new one can be announced.
* **AnnounceOkPacket** is sent back if the announce was ok. It contains the internal id of
the announced game (not related to the game specific id).
* **GameAddedPacket** is broadcast to all connected players to inform them that there is now
a new announced game. Even the original announcer will get it.

### Announce ok
Sent by the server as a response to a game announcement packet and indicates that the game was announced
ok. Contains the game id as assigned by the server.

* game id (`unsigned int`). This is the internal id for the game and has nothing to do with the game id
that was sent in the announcement packet. TODO: this should be changed to avoid confusion.

### Already announced
Error packet sent by the server as a response to an announcement packet and indicates that the player has
already announced a game and can not announce another. A player can have one announced game
at any time.

### Game added
Sent by the server to all players after a player has announced a game. This contains data about the newly announced
game and allows other players to see the game and possibly join it. A player that announces a
game will first get an announce ok packet and then a game added packet for his/her own game. An
added game is available for joining until a player joins it or it is removed for some other reason.

* internal game id (`unsigned int`). This is the internal id for the game.
* game id (`unsigned short`). This is the game specific id that was given in the announcement. This is
totally game specific and not interpreted by the server in any way. It could be a scenario id, a map id
or similar.
* name length (`unsigned short`) of the player that announced the game
* name (name length of characters), not null terminated


### Game removed
Sent by the server after a game has been removed. A game is removed if:

* a player joins an announced game and it starts.
* a player manually leaves a game (see **LeaveGamePacket**) which means the announcement is withdrawn.
* if a player disconnects or crashes the server removes the game that player has announced.

Noteworthy is that a game is removed when it starts. It is to make sure that players looking for games
to join don't see a lot of already started games that they can not join anyway.


### Leave game
Sent by players when they wish to leave or withdraw an announced game.

Responses:

* **NoGamePacket** error sent if the player is not in an active game or does not have an announced game.
* **GameEndedPacket** sent if the player is in an active game with another player. Sent to both players.
* **GameRemovedPacket** sent to all players if the game was announced by the player but not yet joined.

The **GameRemovedPacket** is only sent for games actively announced and not yet joined. Games that have been
started have been removed already for all other players through a **GameRemovedPacket** and only
the two active players know about it.


### No game
### Join game
### Game joined
### Invalid game
### Already has game
### Game full
### Game ended
### Data
### Udp ping
### Udp pong
### Udp data
