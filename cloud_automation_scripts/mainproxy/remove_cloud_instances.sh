#! /bin/bash

if [ -z "$1"  ]; then
	echo "Please enter environment. ex. 
	./remove_cloud_instances.sh stage 
	./remove_cloud_instances.sh prod
	"
exit 1
fi

ENVIRONMENT=$1

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

nova list > novalist_.tmp

function findMainproxyInstance(){
INSTANCES_NO=$1
grep "$MAIN_PROXY_GENERIC-$INSTANCES_NO" novalist_.tmp | awk -F"|" '{print $2}'
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


logMessageToConsole "INFO" "Deleting all $MAIN_PROXY_GENERIC"

MAINPROXY_01=$(findMainproxyInstance "01")
MAINPROXY_02=$(findMainproxyInstance "02")

deleteInstance $MAINPROXY_01
deleteInstance $MAINPROXY_02

rm -f novalist_.tmp

logMessageToConsole "INFO" 'Please wait ...'
sleep 10

nova list 
