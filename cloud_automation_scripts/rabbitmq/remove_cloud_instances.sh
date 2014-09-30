#! /bin/bash

if [ -z "$1" ]; then
echo "Please enter instance group no and environment. ex.
	 ./remove_cloud_instances.sh stage
	 ./remove_cloud_instances.sh prod"
exit 1
fi
ENVIRONMENT=$1

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

nova list > novalist_.tmp

function findRabbitMQInstance(){
INSTANCES_NO=$1
grep "$RABBITMQ_SERVER_GENERIC-$INSTANCES_NO" novalist_.tmp | awk -F"|" '{print $2}'
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

logMessageToConsole "INFO" "Deleting all $RABBITMQ_SERVER_GENERIC"

RABBITMQ_01=$(findRabbitMQInstance "01")
RABBITMQ_02=$(findRabbitMQInstance "02")

deleteInstance $RABBITMQ_01
deleteInstance $RABBITMQ_02

rm -f novalist_.tmp

logMessageToConsole "INFO" 'Please wait ...'
sleep 10

nova list 
