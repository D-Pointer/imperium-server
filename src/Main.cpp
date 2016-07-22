#include <cstdlib>
#include <unistd.h>
#include <sys/param.h>
#include <pwd.h>

#include <iostream>
#include <boost/asio.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/program_options.hpp>

#include "Version.hpp"
#include "Server.hpp"
#include "Log.hpp"
#include "ResourceLoader.hpp"
#include "ManagementServer.hpp"
#include "GlobalStatistics.hpp"

struct Arguments {
    std::string workingDir;
    std::string interface;
    unsigned short port;
    std::string username;
    bool daemonize;
    std::string managementInterface;
    unsigned short managementPort;
};


Arguments validateCommandLineArguments (int argc, char *argv[]) {
    boost::program_options::options_description desc{ "Options" };
    try {
        desc.add_options()
                ( "help,h", "Help screen" )
                ( "workingdir,w", boost::program_options::value<std::string>()->required(),
                  "The directory where all data for the server is, used as a chroot jail." )
                ( "interface,i", boost::program_options::value<std::string>()->default_value( "127.0.0.1" ), "IP address of the interface to listen on." )
                ( "port,p", boost::program_options::value<unsigned short>()->default_value( 11001 ), "Port to listen on." )
                ( "username,u", boost::program_options::value<std::string>()->default_value( "" ),
                  "Name of the user to run as if given (drops root privileges)." )
                ( "daemonize,d", boost::program_options::value<bool>()->default_value( false ), "Daemonize the server and run in the background." )
                ( "managementinterface", boost::program_options::value<std::string>()->default_value( "127.0.0.1" ),
                  "IP address of the management interface to listen on." )
                ( "managementport", boost::program_options::value<unsigned short>()->default_value( 11002 ), "Management port to listen on." );


        boost::program_options::variables_map variablesMap;
        boost::program_options::store( boost::program_options::parse_command_line( argc, argv, desc ), variablesMap );

        if ( variablesMap.count( "help" )) {
            std::cout << desc << std::endl;
            exit( EXIT_SUCCESS );
        }

        boost::program_options::notify( variablesMap );

        return Arguments { variablesMap["workingdir"].as<std::string>(),
                           variablesMap["interface"].as<std::string>(),
                           variablesMap["port"].as<unsigned short>(),
                variablesMap["username"].as<std::string>(),
                variablesMap["daemonize"].as<bool>(),
                variablesMap["managementinterface"].as<std::string>(),
                variablesMap["managementport"].as < unsigned short>() };
    }
    catch (std::exception &ex) {
        std::cerr << "Failed to handle command line arguments: " << ex.what() << std::endl;
        std::cerr << desc << std::endl;
        exit( EXIT_FAILURE );
    }
}


int main (int argc, char *argv[]) {
    std::cout << "Imperium Server" << std::endl;
    std::cout << "Version: " << MAJOR_VERSION << "." << MINOR_VERSION << "." << EXTRA_VERSION << std::endl;
    std::cout << "Build date: " __DATE__ << " " << __TIME__ << std::endl;

    Arguments arguments = validateCommandLineArguments( argc, argv );

    // TODO: chroot jail to the given working dir
    if ( chdir( arguments.workingDir.c_str()) == -1 ) {
        //if ( chroot( argv[1] ) == -1 ) {
        std::cout << "Failed to change to sandbox directory: " << arguments.workingDir << ", reason: " << strerror(errno) << std::endl;
        exit( EXIT_FAILURE );
    }

    std::cout << "Sandbox directory: " << arguments.workingDir << std::endl;

    // should we change effective user?
    if ( arguments.username != "" ) {
        struct passwd pwd;
        struct passwd *result;
        char buffer[16384];
        int s = getpwnam_r( arguments.username.c_str(), &pwd, buffer, 16384, &result );
        if ( result == NULL ) {
            if ( s == 0 ) {
                std::cout << "No such user: " << arguments.username << std::endl;
                exit( EXIT_FAILURE );
            }

            std::cout << "Failed to map user: " << arguments.username << " to a user id: " << strerror(errno) << std::endl;
            exit( EXIT_FAILURE );
        }

        // change user id
        if ( setuid( pwd.pw_uid ) == -1 ) {
            std::cout << "Failed run as user: " << arguments.username << ": " << strerror(errno) << std::endl;
            exit( EXIT_FAILURE );
        }

        std::cout << "Running as user: " << pwd.pw_name << ", user id: " << pwd.pw_uid << std::endl;
    }

    // daemonize the server
    if ( arguments.daemonize ) {
        if ( daemon( 1, 1 ) == -1 ) {
            std::cout << "Failed to daemonize, aborting" << std::endl;
            exit( EXIT_FAILURE );
        }

        std::cout << "Daemonized ok" << std::endl;
    }

    if ( !Log::instance().initialize( "imperium-server.log", 10 * 1024 * 1024, 10 )) {
        // failed to init the log, what to do now?
        std::cout << "Failed to initialize logging, aborting" << std::endl;
        exit( EXIT_FAILURE );
    }

    std::cout << "Log file: " << "imperium-server.log" << std::endl;
    std::cout << "Resource dir: " << ResourceLoader::resourceDir << std::endl;
    std::cout << "IP/port: " << arguments.interface << ":" << arguments.port << std::endl;
    std::cout << "Management IP/port: " << arguments.managementInterface << ":" << arguments.managementPort << std::endl;


    logInfo << "--------------------------------------------------------------------------------------------------------------------";
    logInfo << "version " << MAJOR_VERSION << "." << MINOR_VERSION << "." << EXTRA_VERSION;
    logInfo << "build date: " << GlobalStatistics::instance().m_buildDate << " " << GlobalStatistics::instance().m_buildTime;

    char cwd[ MAXPATHLEN ];
    getcwd( cwd, MAXPATHLEN );
    logInfo << "main: using ip/port: " << arguments.interface << ":" << arguments.port;
    logInfo << "main: using management ip/port: " << arguments.managementInterface << ":" << arguments.managementPort;
    logInfo << "main: sandbox dir: " << arguments.workingDir << ", cwd: " << cwd;
    logInfo << "main: resource dir: " << ResourceLoader::resourceDir;

    if ( arguments.daemonize ) {
        logInfo << "main: running as daemon";
    }

    try {
        boost::asio::io_service ioService;

        // main server
        Server server( ioService, arguments.interface, arguments.port );

        // management server
        ManagementServer managementServer( ioService, arguments.managementInterface, arguments.managementPort );

        ioService.run();
    }
    catch (std::exception &ex) {
        std::cerr << "Exception: " << ex.what() << "\n";
        logCritical << "main: exception caught: " << ex.what();
    }
}
