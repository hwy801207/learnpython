#!/bin/bash
. parameters

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

logMessageToConsole "INFO" "Starting cores ... "
service core-user start
sleep $SLEEP_START_TIME
service core-company start
sleep $SLEEP_START_TIME
service core-messaging start
sleep $SLEEP_START_TIME
service core-engine start
sleep $SLEEP_START_TIME
service core-file start
sleep $SLEEP_START_TIME
service core-banking start
sleep $SLEEP_START_TIME
service core-encryption start
sleep $SLEEP_START_TIME
service core-transaction start
sleep $SLEEP_START_TIME
service core-backend start
