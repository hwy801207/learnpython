#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

echo "Stopping basp-api ..."
service basp-api stop 
sleep 1