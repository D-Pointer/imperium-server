
class Player:

    def __init__ (self, id, name, secret):
    	self.name = name
    	self.id = id
        self.secret = secret


    def __str__ (self):
        return '[Player %d, name: %s, secret: %d]' % ( self.id, self.name, self.secret )
