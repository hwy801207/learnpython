#!/bin/bash
. parameters

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
logMessageToConsole "INFO"  "Please run this bash script as root !"
exit 1
fi
logMessageToConsole "INFO"  "Starting api-user ..."
service api-user start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-auth ..."
service api-auth start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-banking ..."
service api-banking start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-company ..."
service api-company start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-search ..."
service api-search start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-transaction ..."
service api-transaction start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-support ..."
service api-support start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-backend ..."
service api-backend start 
sleep $SLEEP_START_TIME
logMessageToConsole "INFO"  "Starting api-basp ..."
service api-basp start

logMessageToConsole "INFO"  "Api services started !"
