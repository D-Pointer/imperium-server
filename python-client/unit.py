
import random
import struct

class Unit:

    def __init__(self, owner, baseId):
        print "owner: %d, base id: %d" % ( owner, baseId )
        self.id = (0, 100)[owner] + baseId

        self.name = "Unit %d" % self.id
        self.x = random.randrange( 400, 600 )
        self.y = random.randrange( 400, 600 )
        self.rotation = random.randrange( 0, 360 )

        # infantry or cavalry
        self.type = random.randrange( 0, 2 )

        # formation
        self.mode = 0
        self.men = random.randrange( 20, 30 )

        # idle
        self.mission = 11
        self.morale = 100
        self.fatigue = 0

        # regular
        self.experience = 1
        self.ammo = random.randrange( 10, 40 )

        # rifle
        self.weapon = 0


    def getData (self):
        nameLength = len( self.name)
        return struct.pack('>hhhhBBBBBBBBBB%ds' % nameLength, self.id, self.x * 10, self.y * 10, self.rotation * 10, self.type, self.men,
                           self.mode, self.mission, self.morale, self.fatigue, self.experience, self.ammo, self.weapon, nameLength, self.name)


    def getStats (self):
        return struct.pack('>hBBBBBBhhh', self.id, self.men, self.mode, self.mission, self.morale, self.fatigue, self.ammo,
                           self.x * 10, self.y * 10, self.rotation * 10)
