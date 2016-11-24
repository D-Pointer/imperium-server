
import threading
import os.path
import logging

lock = threading.Lock()

nextId = 0

def loadSequence (filename="games.seq"):
    global nextId

    # precautions
    if not os.path.exists( filename ):
        logging.info( "initializing game sequence to 0" )
        nextId = 0
        return

    try:
        nextId = int( open(filename).readline() )
    except:
        logging.error( "failed to read sequence file: %s", filename )
        nextId = 0
        return False

    # loaded ok
    logging.info( "loaded game sequence, next game id: %d", nextId )
    return True


def getNextGameId ():
    global nextId

    lock.acquire()
    id = nextId
    nextId += 1
    lock.release()

    return id

