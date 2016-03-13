#include <cstdlib>
#include <unistd.h>
#include <iostream>
#include <cerrno>

#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include "Version.hpp"
#include "Server.hpp"
#include "Log.hpp"

void usage (const std::string & appname) {
    std::cout << "usage: " << appname << " workingDir port" << std::endl;
    exit( EXIT_FAILURE );
}


int main (int argc, char *argv[]) {
    std::cout << "Imperium Server " << MAJOR_VERSION << "." << MINOR_VERSION << "." << EXTRA_VERSION << std::endl;
    std::cout << "Build date: " __DATE__ << " " << __TIME__ << std::endl;

    if ( argc != 3 ) {
        std::cout << "Invalid arguments" << std::endl;
        usage( argv[0] );
    }

    // change to the working dir
    if ( chdir( argv[1]) == 1 ) {
        std::cout << "Failed to change to working directory: " << argv[1] << ", reason: " << strerror(errno) << std::endl;
        usage( argv[0] );
    }

    std::cout << "Working directory: " << argv[1] << std::endl;

    if ( !Log::instance().initialize( "imperium-server.log", 10 * 1024 * 1024, 10 ) ) {
        // failed to init the log, what to do now?
        std::cout << "Failed to initialize logging, aborting" << std::endl;
        exit(EXIT_FAILURE);
    }

    logInfo << "--------------------------------------------------------------------------------------------------------------------";
    logInfo << "version " << MAJOR_VERSION << "." << MINOR_VERSION << "." << EXTRA_VERSION;
    logInfo << "build date: " __DATE__ << " " << __TIME__;

    int port;

    // parse the port
    try {
        port = boost::lexical_cast<int>( argv[2] );

        if ( port <= 0 || port > 65535 ) {
            throw boost::bad_lexical_cast();
        }
    }
    catch (boost::bad_lexical_cast ex) {
        std::cout << "Invalid port: " << argv[1] << std::endl;
        usage( argv[0] );
    }

    logInfo << "main: using port: " << port;

    try {
        boost::asio::io_service ioService;

        Server server( ioService, port );
        ioService.run();
    }
    catch (std::exception& ex) {
        std::cerr << "Exception: " << ex.what() << "\n";
        logCritical << "main: exception caught: " << ex.what();
    }
}
