cmake_minimum_required(VERSION 2.8)
project(imperium-server)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH}
        /Users/chakie/Work/nemas/libs/osx/lib)

set(SOURCE_FILES
        src/Main.cpp
        src/Log.cpp
        src/Log.hpp
        src/Version.hpp
        src/Server.hpp
        src/Server.cpp
        src/Player.hpp
        src/Player.cpp
        src/Packet.cpp
        src/Packet.hpp
        src/PlayerState.hpp
        src/Errors.hpp
        src/GameManager.cpp
        src/GameManager.hpp
        src/PlayerManager.cpp
        src/PlayerManager.hpp
        src/Game.cpp
        src/Game.hpp
        src/Definitions.hpp
        src/UdpHandler.cpp
        src/UdpHandler.hpp
        src/Statistics.hpp
        src/ResourceLoader.cpp
        src/ResourceLoader.hpp
        src/ManagementServer.hpp
        src/ManagementServer.cpp
        src/ManagementClient.hpp
        src/ManagementClient.cpp
        src/GlobalStatistics.hpp)

add_executable(imperium-server ${SOURCE_FILES})

find_library(BOOST_SYSTEM NAMES libboost_system.a)
find_library(BOOST_FILESYSTEM NAMES libboost_filesystem.a)
find_library(BOOST_PROGRAM_OPTIONS NAMES libboost_program_options.a)
find_library(LOG4CPP liblog4cpp.a)

target_link_libraries(imperium-server ${BOOST_SYSTEM} ${BOOST_FILESYSTEM} ${BOOST_PROGRAM_OPTIONS} ${LOG4CPP} pthread)
