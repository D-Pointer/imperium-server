
import sys

class AuthManager:

    def __init__(self):
        # read in the password
        try:
            self.password = open("password.txt").read().strip()
        except:
            print "AuthManager.init: failed to read the password file, exiting"
            sys.exit( 1 )


    def validatePassword (self, password):
        return self.password == password