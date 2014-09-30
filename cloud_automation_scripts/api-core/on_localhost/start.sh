#!/bin/bash

. parameters

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

./start_core.sh
sleep $SLEEP_CORE_API
./start_api.sh
