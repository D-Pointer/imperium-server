
#include <iostream>

#define LOG4CPP_FIX_ERROR_COLLISION 1

#include <log4cpp/RollingFileAppender.hh>
#include <log4cpp/Layout.hh>
#include <log4cpp/PatternLayout.hh>
#include <log4cpp/Priority.hh>

#include "Log.hpp"


Log * Log::m_log = 0;

Log & Log::instance () {
    if ( Log::m_log == 0 ) {
        Log::m_log = new Log;
    }

    return *Log::m_log;
}


Log::Log () : m_root(log4cpp::Category::getRoot()) {

}


bool Log::initialize (const std::string & logFile, unsigned int maxLogSize, unsigned int maxLogFiles) {
    try {
        m_filename = logFile;

        // the name of the logger
        std::string name = "default";

        // create the rolling file appender appender
        m_appender = new log4cpp::RollingFileAppender( name, m_filename, maxLogSize, maxLogFiles );

        log4cpp::PatternLayout * patternLayout = new log4cpp::PatternLayout;
        patternLayout->setConversionPattern( "%d [%p] %m%n" ); 
        m_appender->setLayout( patternLayout );

        m_root.setPriority( log4cpp::Priority::DEBUG );
        m_root.addAppender( m_appender );

        // all ok
        return true;
    }
    catch ( log4cpp::ConfigureFailure & ex ) {
        std::cerr << "Error initializing log file: " << ex.what() << std::endl;      
    }

    return false;
}
