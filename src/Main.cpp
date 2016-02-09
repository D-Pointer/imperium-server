#include <cstdlib>
#include <iostream>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/bind.hpp>

#include "Version.hpp"
#include "Server.hpp"

void usage (const std::string & appname) {
    std::cout << "usage: " << appname << " port" << std::endl;
    exit( EXIT_FAILURE );

}


int main (int argc, char *argv[]) {
    std::cout << "Imperium Server " << MAJOR_VERSION << "." << MINOR_VERSION << "." << EXTRA_VERSION << std::endl;
    std::cout << "Build date: " __DATE__ << " " << __TIME__ << std::endl;

    if ( argc != 2 ) {
        std::cout << "Invalid arguments" << std::endl;
        usage( argv[0] );
    }

    int port;

    // parse the port
    try {
        port = boost::lexical_cast<int>( argv[1] );

        if ( port <= 0 || port > 65535 ) {
            throw boost::bad_lexical_cast();
        }
    }
    catch (boost::bad_lexical_cast ex) {
        std::cout << "Invalid port: " << argv[1] << std::endl;
        usage( argv[0] );
    }

    try {
        boost::asio::io_service ioService;

        Server server( ioService, port );
        ioService.run();
    }
    catch (std::exception& ex) {
        std::cerr << "Exception: " << ex.what() << "\n";
    }
}
