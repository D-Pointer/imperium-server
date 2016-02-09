
#ifndef IMPERIUM_SERVER_GAME_HPP
#define IMPERIUM_SERVER_GAME_HPP

#include <boost/shared_ptr.hpp>

class Game {

public:

    Game (unsigned short announcedId);

    unsigned int getId () const;

    unsigned int getAnnouncedId () const;


private:

    unsigned int m_id;
    static unsigned int m_nextId;

    // the announced game id
    unsigned short m_announcedId;
};

typedef boost::shared_ptr<Game> SharedGame;

#endif //IMPERIUM_SERVER_GAME_HPP
