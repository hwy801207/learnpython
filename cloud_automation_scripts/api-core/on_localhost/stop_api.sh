#!/bin/bash
. parameters

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
logMessageToConsole "INFO"  "Please run this bash script as root !"
exit 1
fi
logMessageToConsole "INFO"  "Stopping api-user ..."
service api-user stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-auth ..."
service api-auth stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-banking ..."
service api-banking stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-company ..."
service api-company stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-search ..."
service api-search stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-support ..."
service api-support stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-transaction ..."
service api-transaction stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-backend ..."
service api-backend stop 
sleep $SLEEP_STOP_TIME
logMessageToConsole "INFO"  "Stopping api-basp ..."
service api-basp stop

logMessageToConsole "INFO"  "Api services stoped !"
