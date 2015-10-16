
class Player:

	def __init__ (self, name, version):
		self.name = name
		self.version = version


	def __str__ (self):	
		return 'Player: %s, version: %d' % ( self.name, self.version )
		