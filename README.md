# imperium-server
Network server for Imperium.

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

The final binary is `imperium-server` in the `build` directory.



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
* packet type (unsigned short)
* packet length (unsigned short)

The packet length contains the length of the payload. If the packet type does not require any payload this will be 0.
Many packets are simply informational in their nature, i.e. they contain no extra data apart
from the packet type, such as `ServerFullPacket`.

## Packets

### LoginPacket
Sent by clients.

* name length (unsigned short)
* name (name length of characters), not null terminated

Responses:

* `ServerFullPacket`, server full
* `InvalidNamePacket`, invalid name. The name must be 1 to 50 characters long.
* `NameTakenPacket`, name taken by another player.
* `LoginOkPacket` packet.

### Login ok

### Invalid name

### Name taken

### Server full

### Announce
Sent by players when they announce a game that some other player can join.

* game id (unsigned short). This is a game specific id that the server does not interpret in any way.

Responses:

* `AlreadyAnnouncedPacket` if the player has already announced a game. The old game must be
left before a new one can be announced.
* `AnnounceOkPacket` is sent back if the announce was ok. It contains the internal id of
the announced game (not related to the game specific id).
* `GameAddedPacket` is broadcasted to all connected players to inform them that there is now
a new announced game. Even the original announcer will get it.

### Announce ok

### Already announced

### Game added

### Game removed


### Leave game
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
