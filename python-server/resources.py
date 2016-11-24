
import os.path

resourceDir = "resources/"
resourcePartSize = 65000


def loadResource (filename, logger):
    path = resourceDir + filename

    # do we have such a resource?
    if not os.path.exists( path ):
        logger.warning( "resource %s not found: %s", filename )
        return None

    try:
        logger.warning( "loading resource: %s", filename )
        data = open( path, "rb").read()

        # split up into an array of suitable parts
        parts = [data[i:i + resourcePartSize] for i in range(0, len(data), resourcePartSize)]
        return parts

    except:
        logger.error( "failed to read resource: %s", filename )
        return None
