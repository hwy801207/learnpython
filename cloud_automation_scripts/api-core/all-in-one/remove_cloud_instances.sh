#! /bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter rpm version, replica set, instances group and environment 
		./remove_cloud_instances.sh 4866 01 stage
		./remove_cloud_instances.sh 4866 01 prod
		"
exit 1
fi
BUILD_NO=$1
INSTANCES_NO=$2
ENVIRONMENT=$3
REPLICA_SET="01"



. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT


function findInstance(){
GENERIC_NAME=$1
grep $GENERIC_NAME-$BUILD_NO-rs$REPLICA_SET-$INSTANCES_NO novalist_.tmp | awk -F"|" '{print $2}'
}

function deleteInstance(){
INSTANCE_ID=$1
if [ ! -z "$INSTANCE_ID" ]; then
	INSTANCE_NAME=$(grep $INSTANCE_ID novalist_.tmp |  awk -F'|' '{print $3}' | tr -d ' ')
	logMessageToConsole "INFO" "Deleting instance: $INSTANCE_NAME"
	nova delete  $INSTANCE_ID
	removeZabbixHosts "$INSTANCE_NAME"
fi
}

function main(){
nova list > novalist_.tmp
CORE_FILE=$(findInstance $CORE_FILE_GENERIC)
CORE_USER=$(findInstance $CORE_USER_GENERIC)
CORE_MESSAGING=$(findInstance $CORE_MESSAGING_GENERIC)
CORE_BANKING=$(findInstance $CORE_BANKING_GENERIC)
CORE_COMPANY=$(findInstance $CORE_COMPANY_GENERIC)
CORE_ENGINE=$(findInstance $CORE_ENGINE_GENERIC)
CORE_ENCRYPTION=$(findInstance $CORE_ENCRYPTION_GENERIC)
CORE_TRANSACTION=$(findInstance $CORE_TRANSACTION_GENERIC)
CORE_BACKEND=$(findInstance $CORE_BACKEND_GENERIC)

API_USER=$(findInstance $API_USER_GENERIC)
API_AUTH=$(findInstance $API_AUTH_GENERIC)
API_BANKING=$(findInstance $API_BANKING_GENERIC)
API_COMPANY=$(findInstance $API_COMPANY_GENERIC)
API_SEARCH=$(findInstance $API_SEARCH_GENERIC)
API_SUPPORT=$(findInstance $API_SUPPORT_GENERIC)
API_TRANSACTION=$(findInstance $API_TRANSACTION_GENERIC)
API_BACKEND=$(findInstance $API_BACKEND_GENERIC)
API_BASP=$(findInstance $API_BASP_GENERIC)

logMessageToConsole "INFO" "Deleting all api instances $1"
deleteInstance $API_USER
deleteInstance $API_AUTH
deleteInstance $API_BANKING
deleteInstance $API_COMPANY
deleteInstance $API_SEARCH
deleteInstance $API_SUPPORT
deleteInstance $API_TRANSACTION
deleteInstance $API_BACKEND
deleteInstance $API_BASP

logMessageToConsole "INFO" "Deleting all core instances $1"
deleteInstance $CORE_FILE
deleteInstance $CORE_USER
deleteInstance $CORE_MESSAGING
deleteInstance $CORE_BANKING
deleteInstance $CORE_COMPANY
deleteInstance $CORE_ENGINE
deleteInstance $CORE_ENCRYPTION
deleteInstance $CORE_TRANSACTION
deleteInstance $CORE_BACKEND

logMessageToConsole "INFO" 'Please wait ...'
sleep 10
rm -rf novalist_.tmp
nova list 
}

###############execute main###############
main