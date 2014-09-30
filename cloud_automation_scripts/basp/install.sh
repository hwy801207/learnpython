#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
	echo "Please run this bash script as root !"
	exit 1
fi

if [ -z "$1" ]; then
	echo "Please enter basp-build no. ex. $0 0.2.402"
	exit 1
fi
BUILD_NO=$1

. parameters
. functions

##########Stopping services##########
./stop.sh

##########Installing and configuring cores##########
./configure_server.sh $BUILD_NO
if [ "$?" == "4" ]; then
exit 4
fi

waitForCloseConnections

##########Start services##########
./start.sh
