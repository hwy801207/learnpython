#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi
. parameters

BUILD_NO=$1

##########Stopping services##########
./stop.sh


##########Installing and configuring webui##########
echo "Installing and configuring webui default instance ..."
./configure_server.sh $BUILD_NO
sleep 1
echo "webui instance installed ..."

##########Start services##########
./start.sh
