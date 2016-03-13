#ifndef LOG_HPP
#define LOG_HPP

#define LOG4CPP_FIX_ERROR_COLLISION 1

#include <log4cpp/Category.hh>
#include <log4cpp/Appender.hh>

/**
 * Container class for the Log4Cpp logger. This is never used directly, but instead using the
 * macros defined after this class.
 **/
class Log {
public:

    static Log & instance ();

    bool initialize (const std::string & logFile, unsigned int maxLogSize, unsigned int maxLogFiles);

    log4cpp::Category & getRoot () {
        return m_root;
    }

    const std::string & getFilename () const {
        return m_filename;
    }

    
private:

    Log ();

    // singleton instance
    static Log * m_log;

    // the file we log to
    std::string m_filename;
    
    log4cpp::Appender * m_appender;

    //! root logging object
    log4cpp::Category & m_root;
};

#define logDebug\
    Log::instance().getRoot().debugStream()

#define logInfo\
    Log::instance().getRoot().noticeStream()

#define logWarning\
    Log::instance().getRoot().warnStream()

#define logError\
    Log::instance().getRoot().errorStream()

#define logCritical\
    Log::instance().getRoot().critStream()

#endif
