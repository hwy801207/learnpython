#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########Parameters##########
CONNECTIONS_ALIVE_TIME_OUT=1 # if connections are not closed after one minute abort starting ...
SLEEP_TIME=2 # seconds to sleep between two connection closed checks

PORT_API_USER=9000
PORT_API_AUTH=9001
PORT_API_BANKING=9005
PORT_API_COMPANY=9004
PORT_API_SUPPORT=9006
PORT_API_SEARCH=9003
PORT_API_TRANSACTION=9007
PORT_SEARCH_STRING=$PORT_API_USER"\|"$PORT_API_AUTH"\|"$PORT_API_BANKING"\|"$PORT_API_COMPANY"\|"$PORT_API_SUPPORT"\|"$PORT_API_SEARCH"\|"$PORT_API_TRANSACTION

./stop_api.sh

##########Wait for opened connections to close##########
CONNECTIONS=$(netstat -an | grep tcp | grep $PORT_SEARCH_STRING)
echo "Please wait untill all connections are beeing closed ..."
i=1
while [ ! -z "$CONNECTIONS" -a "$i" -le "$(($CONNECTIONS_ALIVE_TIME_OUT*$SLEEP_TIME))" ];
do
CONNECTIONS=$( netstat -an | grep tcp | grep $PORT_SEARCH_STRING)
echo "Still open connections..."
sleep $SLEEP_TIME
((i++))
done
if [ ! -z "$CONNECTIONS" ]; then
echo "Connections have not closed in time... Please close them and the start the new services !"
exit 1
fi

./start_api.sh

