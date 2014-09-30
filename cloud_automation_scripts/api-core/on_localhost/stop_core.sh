#!/bin/bash
. parameters

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi
service core-user stop
sleep $SLEEP_STOP_TIME
service core-company stop
sleep $SLEEP_STOP_TIME
service core-messaging stop
sleep $SLEEP_STOP_TIME
service core-engine stop
sleep $SLEEP_STOP_TIME
service core-file stop
sleep $SLEEP_STOP_TIME
service core-banking stop
sleep $SLEEP_STOP_TIME
service core-encryption stop
sleep $SLEEP_STOP_TIME
service core-transaction stop
sleep $SLEEP_STOP_TIME
service core-backend stop

logMessageToConsole "INFO" "Core services stoped !"

