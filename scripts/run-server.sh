#! /bin/bash

# needed so that boost::filesystem doesn't crash...
export LC_ALL=C

cd /opt/imperium
./imperium_server --workingdir=/opt/imperium --interface 0.0.0.0 --port 11001 --username imperium
