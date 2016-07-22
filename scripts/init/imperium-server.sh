#! /bin/bash

export LC_ALL=C

cd /opt/imperium

ARGS="--workingdir=/opt/imperium --interface 0.0.0.0 --port 11001 --username imperium"

while true; do
    ./imperium-server $ARGS
done
