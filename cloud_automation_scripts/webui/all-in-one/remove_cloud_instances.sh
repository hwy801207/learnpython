#! /bin/bash

if [ -z "$1" -o -z "$2" ]; then
	echo "Please enter build no, instance no and environment. ex. 
		./remove_cloud_instances.sh 1253 stage 
		./remove_cloud_instances.sh 1253 prod
		"
	exit 1
fi

BUILD_NO=$1
ENVIRONMENT=$2


. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

nova list > novalist_.tmp

function findWebuiInstance(){
INSTANCES_NO=$1
grep "webui-$BUILD_NO-$INSTANCES_NO" novalist_.tmp | awk -F"|" '{print $2}'
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

logMessageToConsole "INFO" "Deleting all cloud webui-$BUILD_NO"

WEBUI_01=$(findWebuiInstance "01")
WEBUI_02=$(findWebuiInstance "02")

deleteInstance $WEBUI_01
deleteInstance $WEBUI_02

rm -f novalist_.tmp

logMessageToConsole "INFO" 'Please wait ...'
sleep 10

nova list 
