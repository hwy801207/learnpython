#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

BUILD_NO=$1

. parameters

##########Stopping services##########
./stop.sh

##########Installing and configuring cores##########

./configure_server.sh 'core-user' $BUILD_NO
./configure_server.sh 'core-engine' $BUILD_NO
./configure_server.sh 'core-banking' $BUILD_NO
./configure_server.sh 'core-company' $BUILD_NO
./configure_server.sh 'core-encryption' $BUILD_NO
./configure_server.sh 'core-file' $BUILD_NO
./configure_server.sh 'core-messaging' $BUILD_NO
./configure_server.sh 'core-transaction' $BUILD_NO
./configure_server.sh 'core-backend' $BUILD_NO

./configure_server.sh 'api-user' $BUILD_NO
./configure_server.sh 'api-search'  $BUILD_NO
./configure_server.sh 'api-banking' $BUILD_NO
./configure_server.sh 'api-company' $BUILD_NO
./configure_server.sh 'api-support' $BUILD_NO
./configure_server.sh 'api-auth' $BUILD_NO
./configure_server.sh 'api-transaction' $BUILD_NO
./configure_server.sh 'api-backend' $BUILD_NO
./configure_server.sh 'api-basp' $BUILD_NO

waitForCloseConnections

##########Start services##########
./start.sh
