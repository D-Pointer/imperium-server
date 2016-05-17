
#ifndef RESOURCE_LOADER_HPP
#define RESOURCE_LOADER_HPP

#include <string>
#include <boost/filesystem.hpp>

/**
 * Loads resource files from disc from a "./resources" directory
 */
class ResourceLoader {

public:

    // the name of the resource directory
    static std::string resourceDir;

    static std::string loadResource (const std::string & resourceName);
};


#endif // RESOURCE_LOADER_HPP
