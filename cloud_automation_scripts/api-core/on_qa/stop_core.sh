#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi
service core-user stop
sleep 1
service core-company stop
sleep 1
service core-messaging stop
sleep 1
service core-engine stop
sleep 1
service core-file stop
sleep 1
service core-banking stop
sleep 1
service core-encryption stop
sleep 1
service core-transaction stop
sleep 1
service core-backend stop

echo "Core services stoped !"

