#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

. parameters

./stop.sh

waitForCloseConnections


##########Start services##########
./start.sh
