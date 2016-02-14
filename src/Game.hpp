
#ifndef GAME_HPP
#define GAME_HPP

#include <memory>
#include <string>

class Game {

public:

    Game (unsigned short announcedId);

    unsigned int getId () const;

    unsigned short getAnnouncedId () const;

//    const SharedPlayer & getPlayer1 () const;
//    const SharedPlayer & getPlayer2 () const;

    std::string toString () const;


private:

    unsigned int m_id;
    static unsigned int m_nextId;

    // the announced game id
    unsigned short m_announcedId;

    // the players
//    SharedPlayer m_player1;
//    SharedPlayer m_player2;
};

typedef std::shared_ptr<Game> SharedGame;

#endif //IMPERIUM_SERVER_GAME_HPP
