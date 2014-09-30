#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

echo "Stopping api-user ..."
service api-user stop 
sleep 1
echo "Stopping api-auth ..."
service api-auth stop 
sleep 1
echo "Stopping api-banking ..."
service api-banking stop 
sleep 1
echo "Stopping api-company ..."
service api-company stop 
sleep 1
echo "Stopping api-search ..."
service api-search stop 
sleep 1
echo "Stopping api-support ..."
service api-support stop 
sleep 1
echo "Stopping api-support ..."
service api-transaction stop 

echo "Api services stoped !"