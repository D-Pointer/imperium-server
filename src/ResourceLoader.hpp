
#ifndef RESOURCE_LOADER_HPP
#define RESOURCE_LOADER_HPP

#include <string>
#include <boost/filesystem.hpp>

/**
 * Loads resource files from disc from a
 */
class ResourceLoader {

public:

    static std::string loadResource (const std::string & resourceName);
};


#endif //IMPERIUM_SERVER_RESOURCELOADER_HPP
