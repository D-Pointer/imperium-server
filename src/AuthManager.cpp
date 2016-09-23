#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/algorithm/string/trim.hpp>

#include "AuthManager.hpp"
#include "Log.hpp"

AuthManager &AuthManager::instance () {
    static AuthManager instance;
    return instance;
}


bool AuthManager::initialize (const std::string &filename) {
    std::lock_guard<std::mutex> lock( m_mutex );

    try {
        if ( !boost::filesystem::exists( filename )) {
            std::cout << "AuthManager::initialize: password file: " << filename << " does not exist" << std::endl;
            return false;
        }

        boost::filesystem::ifstream in( filename, std::ios_base::in );
        in >> m_password;
        boost::algorithm::trim( m_password );
    }
    catch (const boost::filesystem::filesystem_error &ex) {
        std::cout << "AuthManager::initialize: failed to read password from: " << filename << ", reason: " << ex.what() << std::endl;
        return false;
    }

    std::cout << "AuthManager::initialize: password: '" << m_password << "'" << std::endl;

    return true;
}


bool AuthManager::validatePassword (const std::string & password) const {
    return password == m_password;
}


const std::string &AuthManager::getPassword () const {
    return m_password;
}


AuthManager::AuthManager () {
}
