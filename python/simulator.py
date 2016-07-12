
import time
import thread
import packet
import random

class Simulator:

    def __init__(self, units, udpSocket, udpAddress):
        self.units = units
        self.udpSocket = udpSocket
        self.udpAddress = udpAddress
        self.keepRunning = True

        self.packetId = 0


    def start (self):
        print "+++ starting simulation loop for %d units" % len(self.units)
        thread.start_new_thread( self.simulationLoop, (None,))


    def stop (self):
        self.keepRunning = False


    def simulationLoop (self, dummy):
        counter = 0

        time.sleep( 1 )

        try:
            while self.keepRunning:
                print "+++ simulating turn %d" % counter

                print "+++ sending missions"
                self.udpSocket.sendto( packet.UdpMissionPacket( self.units, self.packetId ).message, self.udpAddress)
                self.packetId += 1

                print "+++ sending unit stats"
                self.udpSocket.sendto( packet.UdpUnitStatsPacket( self.units, self.packetId ).message, self.udpAddress)
                self.packetId += 1

                # combat?
                if counter > 0 and counter % 20 == 0:
                    attackerId = random.choice( self.units ).id
                    hitX = random.randint( 250, 300 ) * 10
                    hitY = random.randint( 300, 350 ) * 10
                    #targetId = random.randint( 0, 5 )

                    print "+++ sending fire"
                    self.udpSocket.sendto( packet.UdpFirePacket( attackerId, hitX, hitY, None, self.packetId ).message, self.udpAddress)
                    self.packetId += 1

                counter += 1
                time.sleep( 1 )
        except:
            pass

        print "+++ simulation thread done"
