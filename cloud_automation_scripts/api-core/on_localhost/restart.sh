#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

. parameters

##########Stopping services##########
./stop_api.sh
./stop_core.sh

##########Wait for opened connections to close##########
waitForCloseConnections

##########Start services##########
./start_core.sh
./start_api.sh