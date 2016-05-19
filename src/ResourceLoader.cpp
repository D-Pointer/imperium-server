#include <boost/algorithm/string/trim.hpp>
#include <fstream>

#include "ResourceLoader.hpp"
#include "Log.hpp"

std::string ResourceLoader::resourceDir = "resources";

std::string ResourceLoader::loadResource (const std::string &resourceName) {
    boost::filesystem::path resourceRoot( ResourceLoader::resourceDir );

    if ( !boost::filesystem::exists( resourceRoot )) {
        logWarning << "ResourceLoader::loadResource: resource directory not found, can not load resource";
        return std::string();
    }

    boost::filesystem::path resourcePath = resourceRoot;
    resourcePath /= boost::algorithm::trim_copy( resourceName );

    // do not allow absolute paths
    if ( resourcePath.is_absolute()) {
        logWarning << "ResourceLoader::loadResource: resource is an absolute path, not allowed";
        return std::string();
    }

    logDebug << "ResourceLoader::loadResource: loading resource: " << resourcePath.string();

    // does it exist?
    if ( ! boost::filesystem::exists( resourcePath )) {
        logWarning << "ResourceLoader::loadResource: resource not found: " << resourcePath.string();
        return std::string();
    }

    std::ifstream in( resourcePath.string());
    std::stringstream ss;
    ss << in.rdbuf();
    return ss.str();
}
