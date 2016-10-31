
import os.path

resourceDir = "/Users/chakie/Prog/imperium-server/run/resources/"
resourcePartSize = 65000

def loadResource (filename):
    path = resourceDir + filename

    # do we have such a resource?
    if not os.path.exists( path ):
        print "loadResource: resource %s not found" % filename
        return None

    try:
        print "loadResource: loading resource %s" % filename
        data = open( path, "rb").read()

        # split up into an array of suitable parts
        parts = [data[i:i + resourcePartSize] for i in range(0, len(data), resourcePartSize)]
        return parts

    except:
        print "loadResource: failed to read %s" % filename
        return None