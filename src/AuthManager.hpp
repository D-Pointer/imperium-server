#ifndef AUTH_MANAGER_HPP
#define AUTH_MANAGER_HPP

#include <mutex>
#include <set>

#include <boost/filesystem/path.hpp>

class AuthManager {

public:

    static AuthManager & instance ();

    /**
     * Initializes the auth manager and reads the password from the given filename.
     *
     * @param filename
     *
     * @return true if loaded ok and false on error.
     */
    bool initialize (const std::string & filename);

    bool validatePassword (const std::string & password) const;

    const std::string & getPassword () const;


private:

    /**
     * Hidden constructor.
     */
    AuthManager ();

    std::mutex m_mutex;

    std::string m_password;
};


#endif 
