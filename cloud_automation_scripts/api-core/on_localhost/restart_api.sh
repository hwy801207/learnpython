#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

. parameters

PORT_SEARCH_STRING=$PORT_API_USER"\|"$PORT_API_AUTH"\|"$PORT_API_BANKING"\|"$PORT_API_COMPANY"\|"$PORT_API_SUPPORT"\|"$PORT_HTTPS_API_SEARCH"\|"$PORT_HTTPS_API_TRANSACTION"\|"$PORT_HTTPS_API_USER"\|"$PORT_HTTPS_API_AUTH"\|"$PORT_HTTPS_API_BANKING"\|"$PORT_HTTPS_API_COMPANY"\|"$PORT_HTTPS_API_SUPPORT"\|"$PORT_HTTPS_API_SEARCH"\|"$PORT_HTTPS_API_TRANSACTION

./stop_api.sh

##########Wait for opened connections to close##########
waitForCloseConnections

./start_api.sh


