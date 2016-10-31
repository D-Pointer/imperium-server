
class Statistics:

    def __init__(self):
        self.connected = None

        # sent TCP data
        self.tcpPacketsSent = 0
        self.tcpBytesSent = 0
        self.tcpLastSent = None

        # received TCP data
        self.tcpPacketsReceived = 0
        self.tcpBytesReceived = 0
        self.tcpLastReceived = None
