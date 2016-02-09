cmake_minimum_required(VERSION 3.3)
project(imperium_server)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

include_directories( "/Users/chakie/Work/ames/libs/osx/include" )
#link_directories( "/Users/chakie/Work/ames/libs/osx/lib" )
set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH}
        /Users/chakie/Work/ames/libs/osx/lib )

set(SOURCE_FILES
        src/Main.cpp
        src/Version.hpp
        src/Server.hpp
        src/Server.cpp
        src/Session.hpp
        src/Session.cpp
        src/Packet.cpp src/Packet.hpp src/PlayerState.hpp src/Errors.hpp src/GameManager.cpp src/GameManager.hpp src/Game.cpp src/Game.hpp)

add_executable(imperium_server ${SOURCE_FILES})

#find_library( BOOST_FILESYSTEM NAMES libboost_filesystem.a)
find_library( BOOST_SYSTEM NAMES libboost_system.a)
target_link_libraries( imperium_server ${BOOST_SYSTEM} )
#target_link_libraries( imperium_server ${BOOST_CHRONO} ${BOOST_THREAD} ${BOOST_SYSTEM} ${BOOST_FILESYSTEM} ${BOOST_LOG} )
