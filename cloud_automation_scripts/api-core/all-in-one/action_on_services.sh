#!/bin/env bash

ACTION=$1
BUILD_NO=$2

USER='devops'

#INSTANCE TYPES GENERIC NAMES
CORE_USER_GENERIC='core-user'
CORE_COMPANY_GENERIC='core-company'
CORE_ENGINE_GENERIC='core-engine'
CORE_MESSAGING_GENERIC='core-messaging'
CORE_FILE_GENERIC='core-file'
CORE_ENCRYPTION_GENERIC='core-encryption'
CORE_BANKING_GENERIC='core-banking'
CORE_TRANSACTION_GENERIC='core-transaction'
CORE_BACKEND_GENERIC='core-backend'

API_USER_GENERIC='api-user'
API_COMPANY_GENERIC='api-company'
API_SEARCH_GENERIC='api-search'
API_SUPPORT_GENERIC='api-support'
API_AUTH_GENERIC='api-auth'
API_BANKING_GENERIC='api-banking'
API_TRANSACTION_GENERIC='api-transaction'
API_BACKEND_GENERIC='api-backend'
API_BASP_GENERIC='api-basp'

function applyAction(){
  if [ "$ACTION" == "start" -o "$ACTION" == "stop" -o "$ACTION" == "restart" -o "$ACTION" == "status" ]; then
  ssh $USER@$IP "sudo /etc/init.d/$SERVICE $ACTION"
  else
  ssh $USER@$IP "$ACTION"
  fi
  sleep 3
}

function executeFor(){
SERVICE=$1
GROUP_NO=$2

SERVICE_NAME=`grep $SERVICE-$BUILD_NO-rs01-$GROUP_NO list_3 | awk -F' ' '{print $1}'`
IP=`grep $SERVICE-$BUILD_NO-rs01-$GROUP_NO list_3 | awk -F' ' '{print $2}'`
if [ ! -z "$SERVICE_NAME" -a ! -z "$IP" ]; then
    echo "Applying action $ACTION on $SERVICE found on ip: $IP"
    applyAction
else
    echo "No instance was found with name: $SERVICE-$BUILD_NO-rs01-$GROUP_NO"
fi 
}

function executeGroup(){
TYPE=$1
for group in 01 02 
do
  executeFor $TYPE $group
done
}

function restartCores(){
  #all cores in this order
  executeGroup $CORE_FILE_GENERIC
  executeGroup $CORE_USER_GENERIC
  executeGroup $CORE_MESSAGING_GENERIC
  executeGroup $CORE_BANKING_GENERIC
  executeGroup $CORE_COMPANY_GENERIC
  executeGroup $CORE_ENGINE_GENERIC
  executeGroup $CORE_ENCRYPTION_GENERIC
  executeGroup $CORE_TRANSACTION_GENERIC
  executeGroup $CORE_BACKEND_GENERIC


}
function restartApis(){
  #all apis in this order
  executeGroup $API_AUTH_GENERIC
  executeGroup $API_USER_GENERIC
  executeGroup $API_BANKING_GENERIC
  executeGroup $API_COMPANY_GENERIC
  executeGroup $API_SEARCH_GENERIC
  executeGroup $API_SUPPORT_GENERIC
  executeGroup $API_TRANSACTION_GENERIC
  executeGroup $API_BACKEND_GENERIC
  executeGroup $API_BASP_GENERIC
}

function restartAllServices(){
restartCores
restartApis
}

function formIps(){
SER_LIST=`nova list |awk -F "|" '{ print $3,$7 }'|grep -v "Name"|grep -v "^$"|egrep "api|core" > list.txt`
SER_NAME=` cat list.txt |awk -F "," '{print $1}'|awk   '{print $1}'|grep -v "^$"|egrep  "core|api" > list_1`
SER_IP=` cat list.txt |awk -F "," '{print $1}'|awk -F "=" '{print $2}' > list_2`

paste list_1 list_2 > list_3
}

function main(){
if [ "$#" == "2" ];then

formIps
performonemoretime=true
if [ "$ACTION" == "custom" ]; then
  read -p "Please enter the commands to send to servers:
" ACTION
fi

while [ "$performonemoretime" == "true" ]; do
while true; do
read -p "#####################################################################
Please enter which service to $ACTION: 
1 : $CORE_FILE_GENERIC
2 : $CORE_USER_GENERIC
3 : $CORE_MESSAGING_GENERIC
4 : $CORE_BANKING_GENERIC
5 : $CORE_COMPANY_GENERIC
6 : $CORE_ENGINE_GENERIC
7 : $CORE_ENCRYPTION_GENERIC
8 : $CORE_TRANSACTION_GENERIC
9 : $CORE_BACKEND_GENERIC
10 : $API_AUTH_GENERIC
11 : $API_USER_GENERIC
12 : $API_BANKING_GENERIC
13 : $API_COMPANY_GENERIC
14 : $API_SEARCH_GENERIC
15 : $API_SUPPORT_GENERIC
16 : $API_TRANSACTION_GENERIC
17 : $API_BACKEND_GENERIC
18 : $API_BASP_GENERIC
cores : all cores
apis : all apis
all : all services
#####################################################################
" yn
case $yn in
1 ) executeGroup $CORE_FILE_GENERIC ; break;;
2 ) executeGroup $CORE_USER_GENERIC ; break;;
3 ) executeGroup $CORE_MESSAGING_GENERIC ; break;;
4 ) executeGroup $CORE_BANKING_GENERIC ; break;;
5 ) executeGroup $CORE_COMPANY_GENERIC ; break;;
6 ) executeGroup $CORE_ENGINE_GENERIC ; break;;
7 ) executeGroup $CORE_ENCRYPTION_GENERIC ; break;;
8 ) executeGroup $CORE_TRANSACTION_GENERIC ; break;;
9 ) executeGroup $CORE_BACKEND_GENERIC ; break;;
10 ) executeGroup $API_AUTH_GENERIC ; break;;
11 ) executeGroup $API_USER_GENERIC ; break;;
12 ) executeGroup $API_BANKING_GENERIC ; break;;
13 ) executeGroup $API_COMPANY_GENERIC ; break;;
14 ) executeGroup $API_SEARCH_GENERIC ; break;;
15 ) executeGroup $API_SUPPORT_GENERIC ; break;;
16 ) executeGroup $API_TRANSACTION_GENERIC ; break;;
17 ) executeGroup $API_BACKEND_GENERIC ; break;;
18 ) executeGroup $API_BASP_GENERIC ; break;;
cores ) restartCores ; break;;
apis ) restartApis ; break;;
all ) restartAllServices ; break;;
* ) echo "Please answer with one available option
";;
esac    
done
while true ; do
read -p "#####################################################################
Do you want to $ACTION another service? y[es]/n[o]
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
  usage sh $0 {start|restart|status|stop|custom} release
  ex: sh $0  restart  4866
#####################################################################"
fi
}

#########################################
main $1 $2