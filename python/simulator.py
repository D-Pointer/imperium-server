
import time
import thread
import packet

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
        while self.keepRunning:
            print "+++ simulating..."
            time.sleep( 1 )

            print "+++ sending missions"
            self.udpSocket.sendto(packet.UdpMissionPacket( self.units, self.packetId ).message, self.udpAddress)
            self.packetId += 1

        print "+++ simulation thread done"
