
class Player:

	def __init__ (self, id, name, version):
		self.playerId = id
		self.name = name
		self.version = version


	def __str__ (self):	
		return 'Player %d, name: %s, version: %d' % ( self.playerId, self.name, self.version )
		