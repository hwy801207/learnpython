#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi
echo "Starting api-user ..."
service api-user start 
sleep 1
echo "Starting api-auth ..."
service api-auth start 
sleep 1
echo "Starting api-banking ..."
service api-banking start 
sleep 1
echo "Starting api-company ..."
service api-company start 
sleep 1
echo "Starting api-search ..."
service api-search start 
sleep 1
echo "Starting api-support ..."
service api-transaction start 
sleep 1
echo "Starting api-support ..."
service api-support start 
sleep 1
echo "Starting api-backend ..."
service api-backend start 
sleep 1
echo "Starting api-basp ..."
service api-basp start 
echo "Api services started !"




