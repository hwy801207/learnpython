#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

echo "Starting cores ... "
service core-user start
sleep 1
service core-company start
sleep 1
service core-messaging start
sleep 1
service core-engine start
sleep 1
service core-file start
sleep 1
service core-banking start
sleep 1
service core-encryption start
sleep 1
service core-transaction start
sleep 1
service core-backend start