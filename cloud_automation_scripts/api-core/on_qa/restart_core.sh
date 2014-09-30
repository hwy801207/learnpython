#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

. parameters

PORT_SEARCH_STRING=$PORT_USER"\|"$PORT_COMPANY"\|"$PORT_BANKING"\|"$PORT_MESSAGING"\|"$PORT_FILE"\|"$PORT_ENCRYPTION"\|"$PORT_ENGINE"\|"$PORT_TRANSACTION

./stop_core.sh

waitForCloseConnections


./start_core.sh
