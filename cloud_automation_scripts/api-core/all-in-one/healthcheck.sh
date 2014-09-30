#!/bin/bash
BUILD_NO=$1

API_USER_GENERIC='api-user'
API_COMPANY_GENERIC='api-company'
API_SEARCH_GENERIC='api-search'
API_SUPPORT_GENERIC='api-support'
API_AUTH_GENERIC='api-auth'
API_BANKING_GENERIC='api-banking'
API_TRANSACTION_GENERIC='api-transaction'
API_BACKEND_GENERIC='api-backend'
API_BASP_GENERIC='api-basp'

PORT_HTTP_API_USER='9000'
PORT_HTTP_API_AUTH='9001'
PORT_HTTP_API_BASP='9002'
PORT_HTTP_API_SEARCH='9003'
PORT_HTTP_API_COMPANY='9004'
PORT_HTTP_API_BANKING='9005'
PORT_HTTP_API_SUPPORT='9006'
PORT_HTTP_API_TRANSACTION='9007'
PORT_HTTP_API_BACKEND='9009'

function healthCheckApi(){
  local ip=$1 
  local port=$2

  curl -X GET http://$ip:$port/health/full
  echo ""
  #sleep 1
}

function executeFor(){
local SERVICE=$1
local GROUP_NO=$2
local PORT=$3

SERVICE_NAME=`grep $SERVICE-$BUILD_NO-rs01-$GROUP_NO list_3 | awk -F' ' '{print $1}'`
IP=`grep $SERVICE-$BUILD_NO-rs01-$GROUP_NO list_3 | awk -F' ' '{print $2}'`
if [ ! -z "$SERVICE_NAME" -a ! -z "$IP" ]; then
    echo "Healthckeck on $SERVICE found on ip: $IP"
    healthCheckApi $IP $PORT
else
    echo "No instance was found with name: $SERVICE-$BUILD_NO-rs01-$GROUP_NO"
fi 
}

function healthApiGroups(){
local TYPE=$1
local PORT=$2

for group in 01 02 
do
  executeFor $TYPE $group $PORT
done
}


function healthAllApis(){
  #all apis in this order
  healthApiGroups $API_AUTH_GENERIC $PORT_HTTP_API_AUTH
  healthApiGroups $API_USER_GENERIC $PORT_HTTP_API_USER
  healthApiGroups $API_BANKING_GENERIC $PORT_HTTP_API_BANKING
  healthApiGroups $API_COMPANY_GENERIC $PORT_HTTP_API_COMPANY
  healthApiGroups $API_SEARCH_GENERIC $PORT_HTTP_API_SEARCH
  healthApiGroups $API_SUPPORT_GENERIC $PORT_HTTP_API_SUPPORT
  healthApiGroups $API_TRANSACTION_GENERIC $PORT_HTTP_API_TRANSACTION
  healthApiGroups $API_BACKEND_GENERIC $PORT_HTTP_API_BACKEND
  healthApiGroups $API_BASP_GENERIC $PORT_HTTP_API_BASP
}

function formIps(){
SER_LIST=`nova list |awk -F "|" '{ print $3,$7 }'|grep -v "Name"|grep -v "^$"|egrep "api" > list.txt`
SER_NAME=` cat list.txt |awk -F "," '{print $1}'|awk   '{print $1}'|grep -v "^$"|egrep  "api" > list_1`
SER_IP=` cat list.txt |awk -F "," '{print $1}'|awk -F "=" '{print $2}' > list_2`

paste list_1 list_2 > list_3
}

function main(){
if [ "$#" == "1" ];then

formIps
performonemoretime=true

while [ "$performonemoretime" == "true" ]; do
while true; do
read -p "#####################################################################
Please enter which service to $ACTION: 
1 : $API_AUTH_GENERIC
2 : $API_USER_GENERIC
3 : $API_BANKING_GENERIC
4 : $API_COMPANY_GENERIC
5 : $API_SEARCH_GENERIC
6 : $API_SUPPORT_GENERIC
7 : $API_TRANSACTION_GENERIC
8 : $API_BACKEND_GENERIC
9 : $API_BASP_GENERIC
all : all apis
#####################################################################
" yn
case $yn in
1 ) healthApiGroups $API_AUTH_GENERIC $$PORT_HTTP_API_AUTH ; break;;
2 ) healthApiGroups $API_USER_GENERIC $PORT_HTTP_API_USER ; break;;
3 ) healthApiGroups $API_BANKING_GENERIC $PORT_HTTP_API_BANKING ; break;;
4 ) healthApiGroups $API_COMPANY_GENERIC $PORT_HTTP_API_COMPANY ; break;;
5 ) healthApiGroups $API_SEARCH_GENERIC $PORT_HTTP_API_SEARCH ; break;;
6 ) healthApiGroups $API_SUPPORT_GENERIC $PORT_HTTP_API_SUPPORT ; break;;
7 ) healthApiGroups $API_TRANSACTION_GENERIC $PORT_HTTP_API_TRANSACTION ; break;;
8 ) healthApiGroups $API_BACKEND_GENERIC $PORT_HTTP_API_BACKEND; break;;
9 ) healthApiGroups $API_BASP_GENERIC $PORT_HTTP_API_BASP; break;;
all ) healthAllApis ; break;;
* ) echo "Please answer with one available option
";;
esac    
done
while true ; do
read -p "#####################################################################
Do you want to perform healthcheck on another service? y[es]/n[o]
" anotherService
case $anotherService in
[Yy]* ) performonemoretime=true ; break;;
[Nn]* ) performonemoretime=false ; break;;
* ) echo "#####################################################################
Please answer with y[es]/n[o]
";;
esac
done
done
rm -f list_1 list_2 list_3 

else
    echo "
#####################################################################
  usage sh $0 release
  ex: sh $0 4996
#####################################################################"
fi
}

#########################################
main $1