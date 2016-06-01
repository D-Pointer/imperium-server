
#ifndef GLOBAL_STATISTICS_HPP
#define GLOBAL_STATISTICS_HPP

#include <ctime>
#include <string>

/**
 * Singleton class for storing some global statistics.
 */
class GlobalStatistics {

public:

    static GlobalStatistics & instance () {
        static GlobalStatistics globalStatistics;
        return globalStatistics;
    }

    // date and time for when the server was built
    std::string m_buildDate;
    std::string m_buildTime;

    // when was the server started
    time_t m_startTime;

    // number of connected players and managers
    unsigned int m_totalConnectedPlayers;
    unsigned int m_totalConnectedManagers;

    // last connected players and managers
    time_t m_lastConnectedPlayer;
    time_t m_lastConnectedManager;


private:

    GlobalStatistics () {
        m_buildDate = __DATE__;
        m_buildTime = __TIME__;
        m_startTime = time( 0 );
        m_totalConnectedPlayers = 0;
        m_totalConnectedManagers = 0;
        m_lastConnectedPlayer = 0;
        m_lastConnectedManager = 0;
    }
};
#endif
